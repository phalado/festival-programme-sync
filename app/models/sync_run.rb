class SyncRun < ApplicationRecord
  has_many :sync_logs, dependent: :destroy

  enum :status, {
    running: "running",
    completed: "completed",
    failed: "failed"
  }, default: :running

  validates :status, presence: true

  class << self
    def start!
      create!
    rescue ActiveRecord::RecordNotUnique
      nil
    end
  end

  def record_page!(page, total_pages:)
    with_lock do
      return unless running?

      self.total_pages = total_pages
      self.completed_pages |= [ page ]

      complete! if completed_pages.size == total_pages
      save!
    end
  end

  def mark_failed!(error)
    update!(
      status: :failed,
      error_message: error.message,
      finished_at: Time.current
    )
  end

  private

  def complete!
    self.status = :completed
    self.finished_at = Time.current
  end
end
