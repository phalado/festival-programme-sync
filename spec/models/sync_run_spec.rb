require "rails_helper"

RSpec.describe SyncRun, type: :model do
  describe ".start!" do
    it "creates a running sync" do
      expect { described_class.start! }.to change(described_class, :count).by(1)
    end

    it "does not start while another sync is running" do
      described_class.start!

      expect(described_class.start!).to be_nil
    end
  end

  describe "#record_page!" do
    subject(:sync_run) { described_class.create! }

    it "records a completed page once" do
      sync_run.record_page!(1, total_pages: 2)
      sync_run.record_page!(1, total_pages: 2)

      expect(sync_run.reload.completed_pages).to eq([ 1 ])
    end

    it "remains running while pages are outstanding" do
      sync_run.record_page!(1, total_pages: 2)

      expect(sync_run.reload).to be_running
    end

    it "completes after every page finishes" do
      sync_run.record_page!(1, total_pages: 2)
      sync_run.record_page!(2, total_pages: 2)

      expect(sync_run.reload).to be_completed
    end
  end

  describe "#mark_failed!" do
    subject(:sync_run) { described_class.create! }

    it "marks the sync as failed" do
      sync_run.mark_failed!(Faraday::TimeoutError.new("Upstream timed out"))

      expect(sync_run.reload).to be_failed
    end

    it "records the final error" do
      sync_run.mark_failed!(Faraday::TimeoutError.new("Upstream timed out"))

      expect(sync_run.reload.error_message).to eq("Upstream timed out")
    end
  end
end
