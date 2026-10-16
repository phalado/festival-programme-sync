require "rails_helper"

RSpec.describe VenueSync do
  describe "#call" do
    subject(:sync) { described_class.new(payload) }

    let(:payload) do
      [
        {
          "id" => "VEN-01",
          "name" => "Grand Cinema",
          "address" => "12 Main Street",
          "capacity" => 320
        }
      ]
    end

    context "when the venue does not exist" do
      it "creates the venue" do
        expect { sync.call }.to change(Venue, :count).by(1)
      end

      it "imports the venue attributes" do
        sync.call

        expect(Venue.find_by!(external_id: "VEN-01")).to have_attributes(
          name: "Grand Cinema",
          address: "12 Main Street",
          capacity: 320
        )
      end
    end

    context "when the venue is renamed upstream" do
      before do
        Venue.create!(
          external_id: "VEN-01",
          name: "Old Cinema Name",
          address: "Old address",
          capacity: 100
        )
      end

      it "does not create another venue" do
        expect { sync.call }.not_to change(Venue, :count)
      end

      it "updates the venue found by external ID" do
        sync.call

        expect(Venue.find_by!(external_id: "VEN-01")).to have_attributes(
          name: "Grand Cinema",
          address: "12 Main Street",
          capacity: 320
        )
      end
    end

    context "when one venue is invalid" do
      let(:payload) do
        [
          {
            "id" => "VEN-01",
            "name" => "Grand Cinema",
            "address" => "12 Main Street",
            "capacity" => 320
          },
          {
            "id" => "VEN-02",
            "address" => "Missing name",
            "capacity" => 100
          },
          {
            "id" => "VEN-03",
            "name" => "Riverside Cinema",
            "address" => "4 Quay Road",
            "capacity" => 180
          }
        ]
      end

      let(:result) { sync.call }

      it "does not persist the invalid venue" do
        result

        expect(Venue.exists?(external_id: "VEN-02")).to be(false)
      end

      it "continues processing later venues" do
        result

        expect(Venue.exists?(external_id: "VEN-03")).to be(true)
      end

      it "reports the failed external ID" do
        expect(result.failures.map(&:external_id)).to eq([ "VEN-02" ])
      end

      it "reports the error" do
        expect(result.failures.first.error).to be_a(KeyError)
      end

      it "reports successfully processed venues" do
        expect(result.processed_ids).to eq([ "VEN-01", "VEN-03" ])
      end
    end
  end
end
