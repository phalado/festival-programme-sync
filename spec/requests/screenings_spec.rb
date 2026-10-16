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

    it "connects the debounce controller to the form" do
      expect(response.body).to include('data-controller="debounced-submit"')
    end

    it "debounces input from the title field" do
      expect(response.body).to include(
        'data-action="input-&gt;debounced-submit#submit"'
      )
    end

    it "configures the debounce delay" do
      expect(response.body).to include(
        'data-debounced-submit-wait-value="300"'
      )
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

    context "when filtering by date" do
      let!(:matching_screening) do
        create(
          :screening,
          film: create(:film, title: "Autumn in Trieste"),
          starts_at: Time.zone.parse("2027-03-12 20:00:00")
        )
      end
      let!(:other_screening) do
        create(
          :screening,
          film: create(:film, title: "The Silent Orchard"),
          starts_at: Time.zone.parse("2027-03-13 20:00:00")
        )
      end

      before do
        get screenings_path, params: { date: "2027-03-12" }
      end

      it "includes screenings on the selected date" do
        expect(response.body).to include(matching_screening.film.title)
      end

      it "excludes screenings on another date" do
        expect(response.body).not_to include(other_screening.film.title)
      end
    end

    context "when filtering by venue" do
      before do
        get screenings_path, params: { venue_id: matching_screening.venue_id }
      end

      it "includes screenings at the selected venue" do
        expect(response.body).to include(matching_screening.film.title)
      end

      it "excludes screenings at another venue" do
        expect(response.body).not_to include(other_screening.film.title)
      end
    end

    context "when the date is invalid" do
      before do
        get screenings_path, params: { date: "not-a-date" }
      end

      it "returns a successful response" do
        expect(response).to have_http_status(:ok)
      end

      it "does not apply a date filter" do
        expect(response.body).to include(other_screening.film.title)
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
