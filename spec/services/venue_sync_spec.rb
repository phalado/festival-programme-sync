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
  end
end
