class ProgrammeSync
  def initialize(api_client:)
    @api_client = api_client
  end

  def call
    response = @api_client.fetch_screenings(page: 1)

    response.fetch("screenings").each do |attributes|
      sync_screening(attributes)
    end
  end

  private

  def sync_screening(attributes)
    Screening.transaction do
      film = sync_film(attributes.fetch("film"))
      venue = sync_venue(attributes.fetch("venue"))
      screening = Screening.find_or_initialize_by(external_id: attributes.fetch("id"))

      screening.update!(
        film: film,
        venue: venue,
        starts_at: attributes.fetch("starts_at"),
        status: attributes.fetch("status")
      )
    end
  end

  def sync_film(attributes)
    film = Film.find_or_initialize_by(external_id: attributes.fetch("id"))
    film.update!(
      title: attributes.fetch("title"),
      synopsis: attributes["synopsis"],
      runtime: attributes["runtime"],
      year: attributes["year"]
    )
    film
  end

  def sync_venue(attributes)
    venue = Venue.find_or_initialize_by(external_id: attributes.fetch("id"))
    venue.update!(
      name: attributes.fetch("name"),
      address: attributes["address"],
      capacity: attributes["capacity"]
    )
    venue
  end
end
