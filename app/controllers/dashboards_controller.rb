class DashboardsController < ApplicationController
  def show
    @tasks = Task.in_area(life_area)
    @open_tasks = @tasks.unfinished.by_urgency.includes(:project).limit(8)
    @overdue_count = @tasks.overdue.count
    @due_today_count = @tasks.due_today.count
    @done_this_week = @tasks.done.where(completed_at: 1.week.ago..).count

    @projects = Project.in_area(life_area).active.recent.limit(4)
    @notes = Note.in_area(life_area).pinned_first.limit(3)
  end
end
