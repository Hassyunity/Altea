class TasksController < ApplicationController
  before_action :set_task, only: %i[show edit update destroy toggle]

  def index
    scope = Task.in_area(life_area).includes(:project)
    @filter = params[:filter].presence_in(%w[all open done overdue]) || "open"
    @tasks = case @filter
    when "done" then scope.done.order(completed_at: :desc)
    when "overdue" then scope.overdue.by_urgency
    when "all" then scope.by_urgency
    else scope.unfinished.by_urgency
    end
  end

  def show
  end

  def new
    @task = Task.new(life_area: life_area, project_id: params[:project_id])
  end

  def edit
  end

  def create
    @task = Task.new(task_params)
    @task.life_area = life_area

    if @task.save
      redirect_to tasks_path, notice: "Tâche créée."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @task.update(task_params)
      redirect_to tasks_path, notice: "Tâche mise à jour."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @task.destroy!
    redirect_to tasks_path, notice: "Tâche supprimée.", status: :see_other
  end

  def toggle
    @task.toggle_done!
    redirect_back fallback_location: tasks_path
  end

  private

  def set_task
    @task = Task.in_area(life_area).find(params[:id])
  end

  def task_params
    params.expect(task: [ :title, :details, :status, :priority, :due_on, :project_id ])
  end
end
