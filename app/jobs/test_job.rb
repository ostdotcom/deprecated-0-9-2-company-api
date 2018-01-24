class TestJob < ApplicationJob

  queue_as GlobalConstant::Sidekiq.queue_name :default_low_priority_queue

  # Perform method that will be called on job start
  #
  # * Author: Kedar
  # * Date: 24/01/2018
  # * Reviewed By:
  #
  def perform(params)
    Rails.logger.info "Worker started processing ------ params: #{params.inspect}"
  end

end
