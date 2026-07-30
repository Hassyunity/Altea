class ProjectsController < ApplicationController
  before_action :set_project, only: %i[show edit update destroy]

  def index
    @projects = Project.in_area(life_area).recent
  end

  def show
    @tasks = @project.tasks.by_urgency
    @notes = @project.notes.pinned_first
  end

  def new
    @project = Project.new(life_area: life_area, color: "cyan")
  end

  def edit
  end

  def create
    @project = Project.new(project_params)
    @project.life_area = life_area

    if @project.save
      redirect_to @project, notice: "Projet créé."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @project.update(project_params)
      redirect_to @project, notice: "Projet mis à jour."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @project.destroy!
    redirect_to projects_path, notice: "Projet supprimé.", status: :see_other
  end

  private

  def set_project
    @project = Project.in_area(life_area).find(params[:id])
  end

  def project_params
    params.expect(project: [ :name, :description, :status, :color ])
  end
end
