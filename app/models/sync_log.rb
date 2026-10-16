class SyncLog < ApplicationRecord
  belongs_to :sync_run

  enum :log_type, {
    job: "job",
    record: "record"
  }, validate: true

  enum :status, {
    running: "running",
    succeeded: "succeeded",
    failed: "failed"
  }, validate: true

  enum :action, {
    created: "created",
    updated: "updated",
    unchanged: "unchanged",
    deleted: "deleted"
  }, validate: { allow_nil: true }

  validates :started_at, presence: true
  validates :page, presence: true, if: :job?
  validates :record_type, :external_id, presence: true, if: :record?
end
