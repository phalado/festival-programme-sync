require "rails_helper"

RSpec.describe SyncLog, type: :model do
  subject(:sync_log) do
    described_class.new(
      sync_run: sync_run,
      log_type: :job,
      status: :running,
      page: 1,
      started_at: Time.current
    )
  end

  let(:sync_run) { SyncRun.create! }

  it "is valid with job attributes" do
    expect(sync_log).to be_valid
  end

  it "belongs to a sync run" do
    sync_log.sync_run = nil

    expect(sync_log).not_to be_valid
  end

  it "requires a log type" do
    sync_log.log_type = nil

    expect(sync_log).not_to be_valid
  end

  it "requires a status" do
    sync_log.status = nil

    expect(sync_log).not_to be_valid
  end

  it "requires a start time" do
    sync_log.started_at = nil

    expect(sync_log).not_to be_valid
  end

  context "with a job log" do
    it "requires a page" do
      sync_log.page = nil

      expect(sync_log).not_to be_valid
    end
  end

  context "with a record log" do
    subject(:sync_log) do
      described_class.new(
        sync_run: sync_run,
        log_type: :record,
        status: :succeeded,
        action: :created,
        record_type: "Screening",
        external_id: "SCR-0001",
        started_at: Time.current
      )
    end

    it "is valid with record attributes" do
      expect(sync_log).to be_valid
    end

    it "requires a record type" do
      sync_log.record_type = nil

      expect(sync_log).not_to be_valid
    end

    it "requires an external ID" do
      sync_log.external_id = nil

      expect(sync_log).not_to be_valid
    end
  end

  it "defaults metadata to an empty hash" do
    expect(described_class.new.metadata).to eq({})
  end
end
