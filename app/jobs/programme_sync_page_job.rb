class ProgrammeSyncPageJob < ApplicationJob
  queue_as :default

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
