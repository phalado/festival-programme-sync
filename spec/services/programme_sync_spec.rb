require "rails_helper"

RSpec.describe ProgrammeSync do
  describe "#call" do
    subject(:sync) { described_class.new(api_client: api_client) }

    let(:api_client) { double("FestivalApiClient") }
    let(:api_response) do
      {
        "page" => 1,
        "total_pages" => 1,
        "screenings" => [
          {
            "id" => "SCR-0001",
            "starts_at" => "2027-03-06T16:00:00Z",
            "status" => "scheduled",
            "film" => {
              "id" => "FILM-001",
              "title" => "The Silent Orchard",
              "synopsis" => "A beekeeper's last summer in the hills.",
              "runtime" => 118,
              "year" => 2024
            },
            "venue" => {
              "id" => "VEN-01",
              "name" => "Grand Cinema",
              "address" => "12 Main Street",
              "capacity" => 320
            }
          }
        ]
      }
    end

    before { allow(api_client).to receive(:fetch_screenings).with(page: 1).and_return(api_response) }

    it "creates the screening" do
      expect { sync.call }.to change(Screening, :count).by(1)
    end

    it "creates the film" do
      expect { sync.call }.to change(Film, :count).by(1)
    end

    it "creates the venue" do
      expect { sync.call }.to change(Venue, :count).by(1)
    end

    context "when a page is specified" do
      let(:api_response) do
        {
          "page" => 2,
          "total_pages" => 3,
          "screenings" => []
        }
      end

      before do
        allow(api_client).to receive(:fetch_screenings).with(page: 2).and_return(api_response)
      end

      it "requests that page from the API" do
        sync.call(page: 2)

        expect(api_client).to have_received(:fetch_screenings).with(page: 2)
      end

      it "returns the total number of pages" do
        expect(sync.call(page: 2)).to eq(3)
      end
    end

    context "when the API fails after a page was synced" do
      before do
        allow(api_client)
          .to receive(:fetch_screenings)
          .with(page: 2)
          .and_raise(Faraday::ServerError, "Upstream unavailable")

        sync.call(page: 1)
      end

      it "propagates the API failure" do
        expect { sync.call(page: 2) }.to raise_error(Faraday::ServerError)
      end

      it "keeps records committed by the previous page" do
        begin
          sync.call(page: 2)
        rescue Faraday::ServerError
          nil
        end

        expect(Screening.exists?(external_id: "SCR-0001")).to be(true)
      end
    end

    context "when the same page is synced again" do
      before { sync.call }

      it "does not duplicate the screening" do
        expect { sync.call }.not_to change(Screening, :count)
      end

      it "does not duplicate the film" do
        expect { sync.call }.not_to change(Film, :count)
      end

      it "does not duplicate the venue" do
        expect { sync.call }.not_to change(Venue, :count)
      end
    end

    context "when screenings share a film and venue" do
      before do
        second_screening = api_response.fetch("screenings").first.deep_dup
        second_screening["id"] = "SCR-0002"
        api_response.fetch("screenings") << second_screening
      end

      it "creates every screening" do
        expect { sync.call }.to change(Screening, :count).by(2)
      end

      it "syncs the shared film once" do
        allow(sync).to receive(:sync_film).and_call_original

        sync.call

        expect(sync).to have_received(:sync_film).once
      end

      it "syncs the shared venue once" do
        allow(sync).to receive(:sync_venue).and_call_original

        sync.call

        expect(sync).to have_received(:sync_venue).once
      end
    end

    context "when upstream records change" do
      let(:generation_one) do
        api_response.deep_dup.tap do |response|
          second_screening = response.fetch("screenings").first.deep_dup
          second_screening["id"] = "SCR-0002"
          second_screening["film"] = {
            "id" => "FILM-002",
            "title" => "A Quiet Tide",
            "synopsis" => "A fishing village faces the sea, and itself.",
            "runtime" => 95,
            "year" => 2024
          }
          second_screening["venue"] = {
            "id" => "VEN-02",
            "name" => "Riverside Cinema",
            "address" => "4 Quay Road",
            "capacity" => 180
          }
          response.fetch("screenings") << second_screening
        end
      end

      let(:generation_two) do
        generation_one.deep_dup.tap do |response|
          first_screening, second_screening = response.fetch("screenings")

          first_screening["status"] = "cancelled"
          first_screening["film"]["title"] = "The Silent Orchard: Director's Cut"
          first_screening["venue"] = second_screening.fetch("venue").deep_dup
          second_screening["venue"] = generation_one
            .fetch("screenings")
            .first
            .fetch("venue")
            .deep_dup
          second_screening["venue"]["name"] = "Grand Cinema Auditorium"

          added_screening = second_screening.deep_dup
          added_screening["id"] = "SCR-0003"
          response.fetch("screenings") << added_screening
        end
      end

      before do
        allow(api_client)
          .to receive(:fetch_screenings)
          .with(page: 1)
          .and_return(generation_one, generation_two)

        sync.call
        sync.call
      end

      it "moves an existing screening to another venue" do
        screening = Screening.find_by!(external_id: "SCR-0001")

        expect(screening.venue.external_id).to eq("VEN-02")
      end

      it "updates an existing screening status" do
        screening = Screening.find_by!(external_id: "SCR-0001")

        expect(screening.status).to eq("cancelled")
      end

      it "renames an existing film" do
        film = Film.find_by!(external_id: "FILM-001")

        expect(film.title).to eq("The Silent Orchard: Director's Cut")
      end

      it "does not duplicate a renamed film" do
        expect(Film.where(external_id: "FILM-001").count).to eq(1)
      end

      it "renames an existing venue" do
        venue = Venue.find_by!(external_id: "VEN-01")

        expect(venue.name).to eq("Grand Cinema Auditorium")
      end

      it "does not duplicate a renamed venue" do
        expect(Venue.where(external_id: "VEN-01").count).to eq(1)
      end

      it "adds a new screening" do
        expect(Screening.exists?(external_id: "SCR-0003")).to be(true)
      end
    end

    context "after syncing" do
      before { sync.call }

      let(:screening) { Screening.find_by!(external_id: "SCR-0001") }

      it "imports the screening attributes" do
        expect(screening).to have_attributes(
          starts_at: Time.zone.parse("2027-03-06T16:00:00Z"),
          status: "scheduled"
        )
      end

      it "imports the film attributes" do
        expect(screening.film).to have_attributes(
          external_id: "FILM-001",
          title: "The Silent Orchard",
          synopsis: "A beekeeper's last summer in the hills.",
          runtime: 118,
          year: 2024
        )
      end

      it "imports the venue attributes" do
        expect(screening.venue).to have_attributes(
          external_id: "VEN-01",
          name: "Grand Cinema",
          address: "12 Main Street",
          capacity: 320
        )
      end
    end
  end
end
