require "rails_helper"

RSpec.describe "Screenings", type: :request do
  describe "GET /screenings" do
    let!(:matching_screening) do
      create(:screening, film: create(:film, title: "Autumn in Trieste"))
    end
    let!(:other_screening) do
      create(:screening, film: create(:film, title: "The Silent Orchard"))
    end

    before do
      get screenings_path, params: { q: "autumn" }
    end

    it "returns a successful response" do
      expect(response).to have_http_status(:ok)
    end

    it "includes screenings with a matching film title" do
      expect(response.body).to include(matching_screening.film.title)
    end

    it "excludes screenings with a different film title" do
      expect(response.body).not_to include(other_screening.film.title)
    end

    context "when the query contains a SQL wildcard" do
      let!(:matching_screening) do
        create(:screening, film: create(:film, title: "The 100% Film"))
      end

      before do
        get screenings_path, params: { q: "%" }
      end

      it "treats the wildcard as text" do
        expect(response.body).not_to include(other_screening.film.title)
      end
    end
  end
end
