class Note < ApplicationRecord
  include LifeAreaScoped

  belongs_to :project, optional: true

  validates :title, presence: true

  scope :pinned_first, -> { order(pinned: :desc, updated_at: :desc) }
  scope :recent, -> { order(updated_at: :desc) }

  def excerpt(length = 180)
    body.to_s.truncate(length, separator: " ")
  end
end
