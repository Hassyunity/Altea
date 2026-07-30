class Task < ApplicationRecord
  include LifeAreaScoped

  STATUSES = %w[todo doing done].freeze
  PRIORITIES = %w[low normal high urgent].freeze

  belongs_to :project, optional: true

  validates :title, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :priority, inclusion: { in: PRIORITIES }

  before_save :sync_completed_at

  scope :done, -> { where(status: "done") }
  scope :unfinished, -> { where.not(status: "done") }
  scope :overdue, -> { unfinished.where(due_on: ...Date.current) }
  scope :due_today, -> { unfinished.where(due_on: Date.current) }
  scope :upcoming, -> { unfinished.where(due_on: Date.current..) }
  scope :by_urgency, -> { order(Arel.sql("due_on IS NULL, due_on ASC"), created_at: :desc) }

  def done?
    status == "done"
  end

  def overdue?
    due_on.present? && due_on < Date.current && !done?
  end

  def toggle_done!
    update!(status: done? ? "todo" : "done")
  end

  private

  def sync_completed_at
    if done?
      self.completed_at ||= Time.current
    else
      self.completed_at = nil
    end
  end
end
