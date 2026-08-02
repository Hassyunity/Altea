class TransactionsController < ApplicationController
  before_action :set_transaction, only: %i[edit update destroy]
  before_action :load_accounts, only: %i[new create edit update]

  def index
    @month = params[:month].present? ? parse_month(params[:month]) : default_month
    @kind = params[:kind].presence_in(Transaction::KINDS)
    @account_filter = Account.in_area(life_area).find_by(id: params[:account_id])

    scope = Transaction.in_area(life_area).in_month(@month).includes(:account, :transfer_account)
    scope = scope.where(kind: @kind) if @kind

    if @account_filter
      scope = scope.where(account_id: @account_filter.id)
                   .or(scope.where(transfer_account_id: @account_filter.id))
    end

    @transactions = scope.recent

    month_scope = Transaction.in_area(life_area).in_month(@month)
    @expenses_cents = month_scope.expenses.sum(:amount_cents)
    @income_cents = month_scope.income.sum(:amount_cents)
    @by_category = month_scope.expenses.group(:category).sum(:amount_cents).sort_by { |_, cents| -cents }
    @accounts = Account.in_area(life_area).active.ordered
  end

  def new
    @transaction = Transaction.new(
      kind: params[:kind].presence_in(Transaction::KINDS) || "expense",
      occurred_on: Date.current,
      account_id: params[:account_id]
    )
  end

  def edit
  end

  def create
    @transaction = Transaction.new(transaction_params)

    if account_in_area?(@transaction) && @transaction.save
      redirect_to after_save_path, notice: "Opération enregistrée."
    else
      @transaction.errors.add(:account_id, "est introuvable") unless account_in_area?(@transaction)
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @transaction.update(transaction_params)
      redirect_to after_save_path, notice: "Opération mise à jour."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @transaction.destroy!
    redirect_to transactions_path, notice: "Opération supprimée.", status: :see_other
  end

  private

  def set_transaction
    @transaction = Transaction.in_area(life_area).find(params[:id])
  end

  def load_accounts
    @accounts = Account.in_area(life_area).active.ordered
  end

  def transaction_params
    params.expect(transaction: [ :account_id, :transfer_account_id, :kind, :amount, :occurred_on, :category, :description ])
  end

  # Guards against posting an account id from the other life area.
  def account_in_area?(transaction)
    transaction.account_id.present? && Account.in_area(life_area).exists?(id: transaction.account_id)
  end

  def after_save_path
    params[:return_to] == "account" ? account_path(@transaction.account) : transactions_path
  end

  def parse_month(value)
    Date.parse("#{value}-01")
  rescue ArgumentError, TypeError
    Date.current
  end

  # On the 1st of a month the current view would be empty; land on the last
  # month that actually has operations instead.
  def default_month
    Transaction.last_active_month(life_area)
  end
end
