class SyncReporter
  class Null
    def start_job(...)
    end

    def finish_job(...)
    end

    def fail_job(...)
    end

    def record_success(...)
    end

    def record_failure(...)
    end
  end

  def initialize(sync_run:)
    @sync_run = sync_run
  end

  def start_job(page:, attempt:)
    @sync_run.sync_logs.create!(
      log_type: :job,
      status: :running,
      page: page,
      attempt: attempt,
      started_at: Time.current
    )
  end

  def finish_job(log)
    log.update!(
      status: :succeeded,
      finished_at: Time.current
    )
  end

  def fail_job(log, error)
    log.update!(
      status: :failed,
      error_class: error.class.name,
      error_message: error.message,
      finished_at: Time.current
    )
  end

  def record_success(record_type:, external_id:, action:, metadata: {})
    now = Time.current

    @sync_run.sync_logs.create!(
      log_type: :record,
      status: :succeeded,
      action: action,
      record_type: record_type,
      external_id: external_id,
      metadata: metadata,
      started_at: now,
      finished_at: now
    )
  end

  def record_failure(record_type:, external_id:, error:, metadata: {})
    now = Time.current

    @sync_run.sync_logs.create!(
      log_type: :record,
      status: :failed,
      record_type: record_type,
      external_id: external_id,
      error_class: error.class.name,
      error_message: error.message,
      metadata: metadata,
      started_at: now,
      finished_at: now
    )
  end
end
