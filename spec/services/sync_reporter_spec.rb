require "rails_helper"

RSpec.describe SyncReporter do
  subject(:reporter) { described_class.new(sync_run: sync_run) }

  let(:sync_run) { SyncRun.create! }

  describe "#start_job" do
    it "creates a running job log" do
      expect {
        reporter.start_job(page: 2, attempt: 1)
      }.to change(sync_run.sync_logs.job, :count).by(1)
    end

    it "records the page" do
      log = reporter.start_job(page: 2, attempt: 1)

      expect(log.page).to eq(2)
    end

    it "records the attempt" do
      log = reporter.start_job(page: 2, attempt: 3)

      expect(log.attempt).to eq(3)
    end
  end

  describe "#finish_job" do
    it "marks the job as succeeded" do
      log = reporter.start_job(page: 1, attempt: 1)

      reporter.finish_job(log)

      expect(log.reload).to be_succeeded
    end

    it "records when the job finished" do
      log = reporter.start_job(page: 1, attempt: 1)

      reporter.finish_job(log)

      expect(log.reload.finished_at).to be_present
    end
  end

  describe "#fail_job" do
    it "marks the job as failed" do
      log = reporter.start_job(page: 1, attempt: 1)

      reporter.fail_job(log, Faraday::TimeoutError.new("Upstream timed out"))

      expect(log.reload).to be_failed
    end

    it "records the error" do
      log = reporter.start_job(page: 1, attempt: 1)

      reporter.fail_job(log, Faraday::TimeoutError.new("Upstream timed out"))

      expect(log.reload.error_message).to eq("Upstream timed out")
    end
  end

  describe "#record_success" do
    it "creates a successful record log" do
      expect {
        reporter.record_success(
          record_type: "Screening",
          external_id: "SCR-0001",
          action: :created
        )
      }.to change(sync_run.sync_logs.record, :count).by(1)
    end

    it "records the action" do
      log = reporter.record_success(
        record_type: "Screening",
        external_id: "SCR-0001",
        action: :updated
      )

      expect(log).to be_updated
    end
  end

  describe "#record_failure" do
    it "creates a failed record log" do
      expect {
        reporter.record_failure(
          record_type: "Screening",
          external_id: "SCR-0001",
          error: KeyError.new("status is missing")
        )
      }.to change(sync_run.sync_logs.record.failed, :count).by(1)
    end

    it "records the error class" do
      log = reporter.record_failure(
        record_type: "Screening",
        external_id: "SCR-0001",
        error: KeyError.new("status is missing")
      )

      expect(log.error_class).to eq("KeyError")
    end
  end
end
