class ProgrammeSyncPageJob < ApplicationJob
  queue_as :default

  retry_on Faraday::ConnectionFailed,
    Faraday::ServerError,
    Faraday::TimeoutError,
    wait: :polynomially_longer,
    attempts: 5 do |job, error|
      SyncRun.find_by(id: job.arguments.second)&.mark_failed!(error)
    end

  def perform(page, sync_run_id)
    sync_run = SyncRun.find(sync_run_id)
    return unless sync_run.running?

    result = ProgrammeSync.new.call(page: page)
    page_recorded = sync_run.record_page!(page, total_pages: result.total_pages)
    return unless page_recorded

    enqueue_remaining_pages(result.total_pages, sync_run_id) if page == 1
  end

  private

  def enqueue_remaining_pages(total_pages, sync_run_id)
    2.upto(total_pages) do |page|
      self.class.perform_later(page, sync_run_id)
    end
  end
end
