require "rails_helper"

RSpec.describe "Programme sync integration", type: :request do
  let(:build_client) do
    ->(query) do
      client = double("FestivalApiClient")

      allow(client).to receive(:fetch_screenings) do |page:|
        get mock_api_screenings_path, params: query.merge(page: page)

        unless response.successful?
          error = JSON.parse(response.body).fetch("error")
          raise Faraday::ServerError, error
        end

        JSON.parse(response.body)
      end

      client
    end
  end

  let(:sync_all_pages) do
    ->(query) do
      sync = ProgrammeSync.new(api_client: build_client.call(query))
      first_page = sync.call(page: 1)

      2.upto(first_page.total_pages) do |page|
        sync.call(page: page)
      end
    end
  end

  describe "generation 1" do
    before do
      sync_all_pages.call(generation: 1)
    end

    it "imports every screening" do
      expect(Screening.count).to eq(60)
    end

    it "imports every film" do
      expect(Film.count).to eq(12)
    end

    it "imports every venue" do
      expect(Venue.count).to eq(6)
    end
  end

  describe "generation 2" do
    before do
      sync_all_pages.call(generation: 1)
      sync_all_pages.call(generation: 2)
    end

    it "moves screenings to their new venues" do
      expect(
        Screening.find_by!(external_id: "SCR-0001").venue.external_id
      ).to eq("VEN-06")
    end

    it "propagates cancellations" do
      expect(
        Screening.find_by!(external_id: "SCR-0010")
      ).to be_cancelled
    end

    it "updates renamed films without duplication" do
      expect(
        Film.find_by!(external_id: "FILM-005").title
      ).to eq("Autumn in Trieste (Director's Cut)")
    end

    it "updates renamed venues without duplication" do
      expect(
        Venue.find_by!(external_id: "VEN-03").name
      ).to eq("City Gallery Auditorium")
    end

    it "imports newly added screenings" do
      expect(Screening.exists?(external_id: "SCR-0062")).to be(true)
    end
  end

  describe "fail_after=8" do
    subject(:failing_sync) do
      ProgrammeSync.new(
        api_client: build_client.call(generation: 1, fail_after: 8)
      )
    end

    before do
      sync_all_pages.call(generation: 1)
    end

    it "processes the first eight records" do
      expect(failing_sync.call(page: 1).processed_ids.size).to eq(8)
    end

    it "raises when the following page fails" do
      failing_sync.call(page: 1)

      expect {
        failing_sync.call(page: 2)
      }.to raise_error(Faraday::ServerError)
    end

    it "keeps records synchronized before the failure" do
      failing_sync.call(page: 1)

      begin
        failing_sync.call(page: 2)
      rescue Faraday::ServerError
        nil
      end

      expect(Screening.exists?(external_id: "SCR-0060")).to be(true)
    end
  end
end
