require "rails_helper"

RSpec.describe ProgrammeSyncPageJob, type: :job do
  describe "#perform" do
    let(:sync) { instance_double(ProgrammeSync) }
    let(:result) { instance_double(ProgrammeSync::Result, total_pages: 3) }

    before do
      allow(ProgrammeSync).to receive(:new).and_return(sync)
      allow(described_class).to receive(:perform_later)
    end

    context "when processing the first page" do
      before do
        allow(sync).to receive(:call).with(page: 1).and_return(result)
      end

      it "enqueues the second page" do
        described_class.perform_now(1)

        expect(described_class).to have_received(:perform_later).with(2)
      end

      it "enqueues the third page" do
        described_class.perform_now(1)

        expect(described_class).to have_received(:perform_later).with(3)
      end
    end

    context "when processing a subsequent page" do
      before do
        allow(sync).to receive(:call).with(page: 2).and_return(result)
      end

      it "processes the requested page" do
        described_class.perform_now(2)

        expect(sync).to have_received(:call).with(page: 2)
      end

      it "does not enqueue more pages" do
        described_class.perform_now(2)

        expect(described_class).not_to have_received(:perform_later)
      end
    end
  end
end
