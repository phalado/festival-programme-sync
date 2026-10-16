class ProgrammeSync
  def initialize(api_client: FestivalApiClient.new)
    @api_client = api_client
  end

  def call(page: 1)
    response = @api_client.fetch_screenings(page: page)

    response.fetch("screenings").each do |attributes|
      sync_screening(attributes)
    end

    response.fetch("total_pages")
  end

  private

  def sync_screening(attributes)
    Screening.transaction do
      film = sync_film(attributes.fetch("film"))
      venue = sync_venue(attributes.fetch("venue"))
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

      screening.update!(screening_attributes)
    end
  end

  def sync_film(attributes)
    film_attributes = {
      title: attributes.fetch("title"),
      synopsis: attributes["synopsis"],
      runtime: attributes["runtime"],
      year: attributes["year"]
    }
    film = find_or_create_by_external_id(Film, attributes.fetch("id"), film_attributes)

    film.update!(film_attributes)
    film
  end

  def sync_venue(attributes)
    venue_attributes = {
      name: attributes.fetch("name"),
      address: attributes["address"],
      capacity: attributes["capacity"]
    }
    venue = find_or_create_by_external_id(Venue, attributes.fetch("id"), venue_attributes)

    venue.update!(venue_attributes)
    venue
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
