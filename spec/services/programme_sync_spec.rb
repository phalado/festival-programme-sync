require "rails_helper"

RSpec.describe ProgrammeSync do
  describe "#call" do
    it "imports a screening with its film and venue" do
      api_client = double("FestivalApiClient")
      response = {
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

      allow(api_client).to receive(:fetch_screenings).with(page: 1).and_return(response)

      expect {
        described_class.new(api_client: api_client).call
      }.to change(Screening, :count).by(1)
        .and change(Film, :count).by(1)
        .and change(Venue, :count).by(1)

      screening = Screening.find_by!(external_id: "SCR-0001")

      expect(screening).to have_attributes(
        starts_at: Time.zone.parse("2027-03-06T16:00:00Z"),
        status: "scheduled"
      )
      expect(screening.film).to have_attributes(
        external_id: "FILM-001",
        title: "The Silent Orchard",
        synopsis: "A beekeeper's last summer in the hills.",
        runtime: 118,
        year: 2024
      )
      expect(screening.venue).to have_attributes(
        external_id: "VEN-01",
        name: "Grand Cinema",
        address: "12 Main Street",
        capacity: 320
      )
    end
  end
end
