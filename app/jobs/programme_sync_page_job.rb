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
    sync_run = SyncRun.find_by(id: sync_run_id)
    return unless sync_run&.running?

    reporter = SyncReporter.new(sync_run: sync_run)
    job_log = reporter.start_job(page: page, attempt: executions)
    result = ProgrammeSync.new(reporter: reporter).call(page: page)
    page_recorded = sync_run.record_page!(page, total_pages: result.total_pages)
    reporter.finish_job(job_log)
    return unless page_recorded

    enqueue_remaining_pages(result.total_pages, sync_run_id) if page == 1
  rescue StandardError => error
    reporter&.fail_job(job_log, error) if job_log
    raise
  end

  private

  def enqueue_remaining_pages(total_pages, sync_run_id)
    2.upto(total_pages) do |page|
      self.class.perform_later(page, sync_run_id)
    end
  end
end
