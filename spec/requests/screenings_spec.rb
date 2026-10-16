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

    it "targets the screenings Turbo Frame" do
      expect(response.body).to include('data-turbo-frame="screenings"')
    end

    it "wraps the results in the screenings Turbo Frame" do
      expect(response.body).to include('<turbo-frame id="screenings">')
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

    it "does not query film and venue associations per screening" do
      queries = []
      subscriber = ->(_name, _started, _finished, _id, payload) do
        queries << payload.fetch(:sql)
      end

      ActiveSupport::Notifications.subscribed(subscriber, "sql.active_record") do
        get screenings_path
      end

      per_record_queries = queries.grep(
        /WHERE "(?:films|venues)"."id" =/
      )

      expect(per_record_queries).to be_empty
    end
  end
end
