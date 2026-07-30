class NotesController < ApplicationController
  before_action :set_note, only: %i[show edit update destroy pin]

  def index
    @notes = Note.in_area(life_area).includes(:project).pinned_first
  end

  def show
  end

  def new
    @note = Note.new(life_area: life_area, project_id: params[:project_id])
  end

  def edit
  end

  def create
    @note = Note.new(note_params)
    @note.life_area = life_area

    if @note.save
      redirect_to @note, notice: "Note créée."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @note.update(note_params)
      redirect_to @note, notice: "Note mise à jour."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @note.destroy!
    redirect_to notes_path, notice: "Note supprimée.", status: :see_other
  end

  def pin
    @note.update!(pinned: !@note.pinned)
    redirect_back fallback_location: notes_path
  end

  private

  def set_note
    @note = Note.in_area(life_area).find(params[:id])
  end

  def note_params
    params.expect(note: [ :title, :body, :pinned, :project_id ])
  end
end
