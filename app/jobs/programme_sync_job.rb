class ProgrammeSyncJob < ApplicationJob
  queue_as :default

  def perform
    sync_run = SyncRun.start!
    return unless sync_run

    ProgrammeSyncPageJob.perform_later(1, sync_run.id)
  end
end
