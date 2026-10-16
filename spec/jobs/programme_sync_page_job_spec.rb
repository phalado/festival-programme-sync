require "rails_helper"

RSpec.describe ProgrammeSyncPageJob, type: :job do
  describe "#perform" do
    let(:sync) { instance_double(ProgrammeSync) }
    let(:result) { instance_double(ProgrammeSync::Result, total_pages: 3) }
    let(:sync_run) { SyncRun.create! }

    before do
      allow(ProgrammeSync).to receive(:new).and_return(sync)
      allow(described_class).to receive(:perform_later)
    end

    context "when processing the first page" do
      before do
        allow(sync).to receive(:call).with(page: 1).and_return(result)
      end

      it "enqueues the second page" do
        described_class.perform_now(1, sync_run.id)

        expect(described_class).to have_received(:perform_later).with(2, sync_run.id)
      end

      it "enqueues the third page" do
        described_class.perform_now(1, sync_run.id)

        expect(described_class).to have_received(:perform_later).with(3, sync_run.id)
      end

      it "records the completed page" do
        described_class.perform_now(1, sync_run.id)

        expect(sync_run.reload.completed_pages).to eq([ 1 ])
      end

      it "logs the successful job" do
        described_class.perform_now(1, sync_run.id)

        expect(sync_run.sync_logs.job.succeeded.count).to eq(1)
      end
    end

    context "when processing a subsequent page" do
      before do
        allow(sync).to receive(:call).with(page: 2).and_return(result)
      end

      it "processes the requested page" do
        described_class.perform_now(2, sync_run.id)

        expect(sync).to have_received(:call).with(page: 2)
      end

      it "does not enqueue more pages" do
        described_class.perform_now(2, sync_run.id)

        expect(described_class).not_to have_received(:perform_later)
      end
    end

    context "when processing the final page" do
      before do
        sync_run.record_page!(1, total_pages: 3)
        sync_run.record_page!(2, total_pages: 3)
        allow(sync).to receive(:call).with(page: 3).and_return(result)
      end

      it "completes the sync run" do
        described_class.perform_now(3, sync_run.id)

        expect(sync_run.reload).to be_completed
      end
    end

    context "when the sync run is no longer active" do
      before do
        sync_run.mark_failed!(Faraday::TimeoutError.new("Upstream timed out"))
        allow(sync).to receive(:call)
      end

      it "does not process the page" do
        described_class.perform_now(2, sync_run.id)

        expect(sync).not_to have_received(:call)
      end
    end

    context "when the API has a transient failure" do
      subject(:job) { described_class.new(1, sync_run.id) }

      before do
        allow(sync).to receive(:call).with(page: 1).and_raise(error)
        allow(job).to receive(:retry_job)
        job.perform_now
      end

      context "with a server error" do
        let(:error) { Faraday::ServerError.new("Upstream unavailable") }

        it "retries the job" do
          expect(job).to have_received(:retry_job)
        end
      end

      context "with a timeout" do
        let(:error) { Faraday::TimeoutError.new("Upstream timed out") }

        it "retries the job" do
          expect(job).to have_received(:retry_job)
        end

        it "logs the failed attempt" do
          expect(sync_run.sync_logs.job.failed.count).to eq(1)
        end
      end

      context "with a connection failure" do
        let(:error) { Faraday::ConnectionFailed.new("Upstream unreachable") }

        it "retries the job" do
          expect(job).to have_received(:retry_job)
        end
      end
    end

    context "when retries are exhausted" do
      subject(:job) { described_class.new(1, sync_run.id) }

      before do
        allow(sync).to receive(:call).with(page: 1).and_raise(
          Faraday::TimeoutError,
          "Upstream timed out"
        )
        retryable_errors = [
          Faraday::ConnectionFailed,
          Faraday::ServerError,
          Faraday::TimeoutError
        ]
        job.exception_executions = { retryable_errors.to_s => 4 }
      end

      it "marks the sync run as failed" do
        job.perform_now

        expect(sync_run.reload).to be_failed
      end
    end
  end
end
