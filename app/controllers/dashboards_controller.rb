class DashboardsController < ApplicationController
  def show
    @tasks = Task.in_area(life_area)
    @open_tasks = @tasks.unfinished.by_urgency.includes(:project).limit(8)
    @overdue_count = @tasks.overdue.count
    @due_today_count = @tasks.due_today.count
    @done_this_week = @tasks.done.where(completed_at: 1.week.ago..).count

    @projects = Project.in_area(life_area).active.recent.limit(4)
    @notes = Note.in_area(life_area).pinned_first.limit(3)

    load_money_summary
  end

  private

  # Banking lives in the personal area only.
  def load_money_summary
    return unless life_area == "personal"

    @accounts = Account.in_area(life_area).active.ordered
    @balances = Account.balances_for(@accounts)
    @total_by_currency = @accounts.group_by(&:currency).transform_values do |group|
      group.sum { |account| @balances.fetch(account, 0) }
    end

    @money_month = Transaction.last_active_month(life_area)
    month = Transaction.in_area(life_area).in_month(@money_month)
    @month_expenses = month.expenses.sum(:amount_cents)
    @month_income = month.income.sum(:amount_cents)
  end
end
