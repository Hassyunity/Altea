class Transaction < ApplicationRecord
  include MoneyAttribute

  KINDS = %w[expense income transfer].freeze

  CATEGORIES = [
    "Alimentation", "Transport", "Logement", "Factures", "Santé", "Éducation",
    "Famille", "Loisirs", "Vêtements", "Téléphone & Internet", "Épargne",
    "Salaire", "Prime", "Vente", "Cadeau", "Divers"
  ].freeze

  belongs_to :account
  belongs_to :transfer_account, class_name: "Account", optional: true, inverse_of: :incoming_transfers

  money_attribute :amount

  validates :kind, inclusion: { in: KINDS }
  validates :amount_cents, numericality: { greater_than: 0 }
  validates :occurred_on, presence: true
  validate :transfer_needs_a_distinct_destination

  scope :expenses, -> { where(kind: "expense") }
  scope :income, -> { where(kind: "income") }
  scope :transfers, -> { where(kind: "transfer") }
  scope :recent, -> { order(occurred_on: :desc, id: :desc) }
  scope :in_area, ->(area) { joins(:account).where(accounts: { life_area: area }) }
  scope :in_month, ->(date) { where(occurred_on: date.beginning_of_month..date.end_of_month) }

  # The month a summary should show: the current one, unless it is still empty
  # (early in a month), in which case the latest month holding operations.
  def self.last_active_month(area)
    scope = in_area(area)
    return Date.current if scope.in_month(Date.current).exists?

    scope.maximum(:occurred_on)&.beginning_of_month || Date.current
  end

  def expense? = kind == "expense"
  def income? = kind == "income"
  def transfer? = kind == "transfer"

  def currency
    account&.currency || "MGA"
  end

  # Signed amount from the point of view of one account.
  def signed_cents_for(account_id)
    return amount_cents if income? || (transfer? && transfer_account_id == account_id)

    -amount_cents
  end

  # nil when the operation has neither libellé nor catégorie; the view then
  # falls back to the localised kind name.
  def label
    description.presence || category.presence
  end

  private

  def transfer_needs_a_distinct_destination
    return unless transfer?

    if transfer_account_id.blank?
      errors.add(:base, "Un virement doit avoir un compte destinataire.")
    elsif transfer_account_id == account_id
      errors.add(:base, "Le compte destinataire doit être différent du compte source.")
    end
  end
end
