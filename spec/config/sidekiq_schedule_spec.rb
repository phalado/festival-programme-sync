require "rails_helper"

RSpec.describe "Sidekiq schedule" do
  subject(:programme_sync) do
    YAML.safe_load_file(Rails.root.join("config/sidekiq_schedule.yml"))
      .fetch("programme_sync")
  end

  it "runs the programme sync hourly" do
    expect(programme_sync.fetch("cron")).to eq("0 * * * *")
  end

  it "starts the sync coordinator job" do
    expect(programme_sync.fetch("class")).to eq("ProgrammeSyncJob")
  end

  it "does not require arguments" do
    expect(programme_sync.fetch("args")).to eq([])
  end

  it "uses the default queue" do
    expect(programme_sync.fetch("queue")).to eq("default")
  end
end
