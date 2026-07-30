module LifeAreaScoped
  extend ActiveSupport::Concern

  LIFE_AREAS = %w[work personal].freeze

  included do
    validates :life_area, presence: true, inclusion: { in: LIFE_AREAS }

    scope :in_area, ->(area) { where(life_area: area) }
    scope :work, -> { in_area("work") }
    scope :personal, -> { in_area("personal") }
  end

  def work?
    life_area == "work"
  end

  def personal?
    life_area == "personal"
  end
end
