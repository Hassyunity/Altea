class AccountsController < ApplicationController
  before_action :set_account, only: %i[show edit update destroy]

  def index
    @accounts = Account.in_area(life_area).ordered
    @balances = Account.balances_for(@accounts)
    @totals_by_currency = totals_by_currency(@accounts.reject(&:archived?))

    @month = Transaction.last_active_month(life_area)
    scope = Transaction.in_area(life_area).in_month(@month)
    @month_expenses = scope.expenses.sum(:amount_cents)
    @month_income = scope.income.sum(:amount_cents)
  end

  def show
    @transactions = Transaction.where(account_id: @account.id)
                               .or(Transaction.where(transfer_account_id: @account.id))
                               .includes(:account, :transfer_account)
                               .recent
                               .limit(60)
    @balance_cents = @account.balance_cents
  end

  def new
    @account = Account.new(life_area: life_area, kind: "bank", currency: "MGA", color: "cyan")
  end

  def edit
  end

  def create
    @account = Account.new(account_params)
    @account.life_area = life_area

    if @account.save
      redirect_to @account, notice: "Compte créé."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @account.update(account_params)
      redirect_to @account, notice: "Compte mis à jour."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @account.destroy!
    redirect_to accounts_path, notice: "Compte supprimé.", status: :see_other
  end

  private

  def set_account
    @account = Account.in_area(life_area).find(params[:id])
  end

  def account_params
    params.expect(account: [ :name, :kind, :institution, :currency, :opening_balance, :color, :notes, :archived ])
  end

  # Currencies are never summed together.
  def totals_by_currency(accounts)
    balances = Account.balances_for(accounts)
    accounts.group_by(&:currency).transform_values do |group|
      group.sum { |account| balances.fetch(account, 0) }
    end
  end
end
