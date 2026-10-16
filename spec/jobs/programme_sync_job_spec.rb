require "rails_helper"

RSpec.describe ProgrammeSyncJob, type: :job do
  describe "#perform" do
    before do
      allow(ProgrammeSyncPageJob).to receive(:perform_later)
    end

    it "starts a sync run" do
      expect { described_class.perform_now }.to change(SyncRun, :count).by(1)
    end

    it "enqueues the first page for the run" do
      described_class.perform_now
      sync_run = SyncRun.last

      expect(ProgrammeSyncPageJob).to have_received(:perform_later).with(1, sync_run.id)
    end

    context "when another sync is running" do
      before do
        SyncRun.create!
      end

      it "does not start another run" do
        expect { described_class.perform_now }.not_to change(SyncRun, :count)
      end

      it "does not enqueue another page job" do
        described_class.perform_now

        expect(ProgrammeSyncPageJob).not_to have_received(:perform_later)
      end
    end
  end
end
