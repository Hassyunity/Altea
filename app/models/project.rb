class Project < ApplicationRecord
  include LifeAreaScoped

  STATUSES = %w[active paused done].freeze
  COLORS = %w[cyan azure violet amber emerald rose].freeze

  has_many :tasks, dependent: :nullify
  has_many :notes, dependent: :nullify

  validates :name, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :color, inclusion: { in: COLORS }, allow_blank: true

  scope :active, -> { where(status: "active") }
  scope :recent, -> { order(updated_at: :desc) }

  def progress
    total = tasks.count
    return 0 if total.zero?

    (tasks.done.count * 100.0 / total).round
  end
end
