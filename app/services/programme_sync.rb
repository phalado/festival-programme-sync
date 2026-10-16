class ProgrammeSync
  Failure = Data.define(:external_id, :error)
  Result = Data.define(:total_pages, :processed_ids, :failures)
  INVALID_RECORD_ERRORS = [
    ActiveRecord::RecordInvalid,
    ArgumentError,
    KeyError
  ].freeze

  def initialize(api_client: FestivalApiClient.new, reporter: SyncReporter::Null.new)
    @api_client = api_client
    @reporter = reporter
  end

  def call(page: 1)
    response = @api_client.fetch_screenings(page: page)
    films = {}
    venues = {}
    processed_ids = []
    failures = []

    response.fetch("screenings").each do |attributes|
      sync_screening(attributes, films: films, venues: venues)
      processed_ids << attributes.fetch("id")
    rescue *INVALID_RECORD_ERRORS => error
      failures << Failure.new(external_id: attributes["id"], error: error)
      @reporter.record_failure(
        record_type: "Screening",
        external_id: attributes["id"].presence || "unknown",
        error: error
      )
    end

    Result.new(
      total_pages: response.fetch("total_pages"),
      processed_ids: processed_ids,
      failures: failures
    )
  end

  private

  def sync_screening(attributes, films:, venues:)
    film_attributes = attributes.fetch("film")
    venue_attributes = attributes.fetch("venue")
    film_external_id = film_attributes.fetch("id")
    venue_external_id = venue_attributes.fetch("id")
    film = nil
    venue = nil

    Screening.transaction do
      film = films[film_external_id] || sync_film(film_attributes)
      venue = venues[venue_external_id] || sync_venue(venue_attributes)
      screening_attributes = {
        film: film,
        venue: venue,
        starts_at: attributes.fetch("starts_at"),
        status: attributes.fetch("status")
      }
      screening = find_or_create_by_external_id(
        Screening,
        attributes.fetch("id"),
        screening_attributes
      )
      action = action_for(screening, screening_attributes)

      screening.update!(screening_attributes)
      report_success(screening, action)
    end

    films[film_external_id] = film
    venues[venue_external_id] = venue
  end

  def sync_film(attributes)
    film_attributes = {
      title: attributes.fetch("title"),
      synopsis: attributes["synopsis"],
      runtime: attributes["runtime"],
      year: attributes["year"]
    }
    film = find_or_create_by_external_id(Film, attributes.fetch("id"), film_attributes)
    action = action_for(film, film_attributes)

    film.update!(film_attributes)
    report_success(film, action)
    film
  end

  def sync_venue(attributes)
    venue_attributes = {
      name: attributes.fetch("name"),
      address: attributes["address"],
      capacity: attributes["capacity"]
    }
    venue = find_or_create_by_external_id(Venue, attributes.fetch("id"), venue_attributes)
    action = action_for(venue, venue_attributes)

    venue.update!(venue_attributes)
    report_success(venue, action)
    venue
  end

  def action_for(record, attributes)
    return :created if record.previously_new_record?

    record.assign_attributes(attributes)
    return :updated if record.changed?

    :unchanged
  end

  def report_success(record, action)
    @reporter.record_success(
      record_type: record.class.name,
      external_id: record.external_id,
      action: action
    )
  end

  def find_or_create_by_external_id(model, external_id, attributes)
    model.find_or_create_by!(external_id: external_id) do |record|
      record.assign_attributes(attributes)
    end
  rescue ActiveRecord::RecordInvalid => error
    raise unless uniqueness_conflict?(error)

    model.find_by!(external_id: external_id)
  end

  def uniqueness_conflict?(error)
    error.record.errors.attribute_names == [ :external_id ] &&
      error.record.errors.added?(:external_id, :taken)
  end
end
