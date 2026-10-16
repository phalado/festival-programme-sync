class ProgrammeSyncPageJob < ApplicationJob
  queue_as :default

  retry_on Faraday::ConnectionFailed,
    Faraday::ServerError,
    Faraday::TimeoutError,
    wait: :polynomially_longer,
    attempts: 5

  def perform(page = 1)
    result = ProgrammeSync.new.call(page: page)

    enqueue_remaining_pages(result.total_pages) if page == 1
  end

  private

  def enqueue_remaining_pages(total_pages)
    2.upto(total_pages) do |page|
      self.class.perform_later(page)
    end
  end
end
