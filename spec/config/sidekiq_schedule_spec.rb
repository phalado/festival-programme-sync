require "rails_helper"

RSpec.describe "Sidekiq schedule" do
  subject(:programme_sync) do
    YAML.safe_load_file(Rails.root.join("config/sidekiq_schedule.yml"))
      .fetch("programme_sync")
  end

  it "runs the programme sync hourly" do
    expect(programme_sync.fetch("cron")).to eq("0 * * * *")
  end

  it "starts the page sync job" do
    expect(programme_sync.fetch("class")).to eq("ProgrammeSyncPageJob")
  end

  it "starts with the first page" do
    expect(programme_sync.fetch("args")).to eq([ 1 ])
  end

  it "uses the default queue" do
    expect(programme_sync.fetch("queue")).to eq("default")
  end
end
