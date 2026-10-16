require "rails_helper"

RSpec.describe FestivalApiClient do
  describe "timeouts" do
    subject(:connection) do
      described_class.new.instance_variable_get(:@connection)
    end

    it "allows the known slow response to complete" do
      expect(connection.options.timeout).to eq(10)
    end

    it "limits the time spent opening a connection" do
      expect(connection.options.open_timeout).to eq(2)
    end
  end

  describe "#fetch_screenings" do
    subject(:client) { described_class.new(connection: connection) }

    let(:connection) { double("Faraday::Connection") }
    let(:response) { double("Faraday::Response", body: api_response) }
    let(:api_response) do
      {
        "page" => 2,
        "total_pages" => 3,
        "screenings" => []
      }
    end

    before do
      allow(connection).to receive(:get).with("/mock_api/screenings", page: 2).and_return(response)
    end

    it "requests the selected page" do
      client.fetch_screenings(page: 2)

      expect(connection).to have_received(:get).with("/mock_api/screenings", page: 2)
    end

    it "returns the response body" do
      expect(client.fetch_screenings(page: 2)).to eq(api_response)
    end
  end
end
