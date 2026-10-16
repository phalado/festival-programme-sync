class FestivalApiClient
  def initialize(connection: default_connection)
    @connection = connection
  end

  def fetch_screenings(page:)
    @connection.get("/mock_api/screenings", page: page).body
  end

  private

  def default_connection
    Faraday.new(
      url: ENV.fetch("FESTIVAL_API_URL"),
      request: {
        open_timeout: 2,
        timeout: 10
      }
    ) do |connection|
      connection.response :raise_error
      connection.response :json
    end
  end
end
