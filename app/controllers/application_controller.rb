class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :set_life_area

  helper_method :life_area, :work_area?

  private

  # Every route is nested under /work or /personal, so the area is always known.
  def set_life_area
    @life_area = params[:life_area].presence_in(LifeAreaScoped::LIFE_AREAS) || "work"
  end

  def life_area
    @life_area
  end

  def work_area?
    life_area == "work"
  end

  # Keeps the current area in every generated path helper.
  def default_url_options
    { life_area: life_area }
  end
end
