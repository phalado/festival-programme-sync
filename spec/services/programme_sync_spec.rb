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
