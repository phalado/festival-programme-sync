# Keeps our local venue records in step with the upstream festival system.
#
# Inherited from the previous programming integration. Given an array of venue
# hashes from the API, it upserts each one into our venues table.
#
#   VenueSync.new(venues_payload).call
#
# where each entry looks like:
#   { "id" => "VEN-01", "name" => "Grand Cinema", "address" => "...", "capacity" => 320 }
class VenueSync
  Failure = Data.define(:external_id, :error)
  Result = Data.define(:processed_ids, :failures)
  INVALID_RECORD_ERRORS = [
    ActiveRecord::RecordInvalid,
    ArgumentError,
    KeyError
  ].freeze

  def initialize(venues)
    @venues = venues
  end

  def call
    processed_ids = []
    failures = []

    @venues.each do |attrs|
      venue = Venue.find_or_initialize_by(external_id: attrs.fetch("id"))
      venue.update!(
        name: attrs.fetch("name"),
        address: attrs["address"],
        capacity: attrs["capacity"]
      )
      processed_ids << attrs.fetch("id")
    rescue *INVALID_RECORD_ERRORS => error
      failures << Failure.new(external_id: attrs["id"], error: error)
    end

    Result.new(processed_ids: processed_ids, failures: failures)
  end
end
