class Account < ApplicationRecord
  include LifeAreaScoped
  include MoneyAttribute

  KINDS = %w[bank mvola orange_money airtel_money safe cash].freeze
  CURRENCIES = %w[MGA EUR USD].freeze
  COLORS = %w[cyan azure violet amber emerald rose].freeze

  has_many :transactions, dependent: :destroy
  has_many :incoming_transfers, class_name: "Transaction",
                                foreign_key: :transfer_account_id,
                                inverse_of: :transfer_account,
                                dependent: :nullify

  money_attribute :opening_balance

  validates :name, presence: true
  validates :kind, inclusion: { in: KINDS }
  validates :currency, inclusion: { in: CURRENCIES }
  validates :color, inclusion: { in: COLORS }, allow_blank: true

  scope :active, -> { where(archived: false) }
  scope :ordered, -> { order(:archived, :kind, :name) }

  # Cash actually in hand or in a vault, as opposed to money held by an institution.
  def cash_like?
    kind.in?(%w[safe cash])
  end

  def balance_cents
    opening_balance_cents + credits_cents - debits_cents
  end

  # One grouped query per direction instead of four per account.
  def self.balances_for(accounts)
    ids = accounts.map(&:id)
    return {} if ids.empty?

    incoming = Transaction.where(account_id: ids, kind: "income").group(:account_id).sum(:amount_cents)
    outgoing = Transaction.where(account_id: ids, kind: %w[expense transfer]).group(:account_id).sum(:amount_cents)
    received = Transaction.where(transfer_account_id: ids, kind: "transfer").group(:transfer_account_id).sum(:amount_cents)

    accounts.index_with do |account|
      account.opening_balance_cents +
        incoming.fetch(account.id, 0) + received.fetch(account.id, 0) -
        outgoing.fetch(account.id, 0)
    end
  end

  private

  def credits_cents
    transactions.income.sum(:amount_cents) + incoming_transfers.transfers.sum(:amount_cents)
  end

  def debits_cents
    transactions.where(kind: %w[expense transfer]).sum(:amount_cents)
  end
end
