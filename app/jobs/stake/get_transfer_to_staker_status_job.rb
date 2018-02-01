class Stake::GetTransferToStakerStatusJob < ApplicationJob

  include Util::ResultHelper

  queue_as GlobalConstant::Sidekiq.queue_name :default_medium_priority_queue

  # Perform
  #
  # * Author: Puneet
  # * Date: 01/02/2018
  # * Reviewed By:
  #
  # @param [String] transaction_hash (mandatory) - hash
  # @param [Integer] client_setup_activity_log_id (mandatory) - id of ClientSetupActivityLog
  # @param [Integer] started_at (mandatory) - timestamp when this job was first enqueued
  #
  def perform(params)

    init_params(params)

    r = validate
    return r unless r.success?

  end

  private

  #
  # * Author: Puneet
  # * Date: 01/02/2018
  # * Reviewed By:
  #
  # @param [Hash] params
  #
  def init_params(params)

    @transaction_hash = params[:transaction_hash]
    @client_setup_activity_log_id = params[:client_setup_activity_log_id]
    @started_at = params[:started_at]

    @client_setup_activity_log = nil

    @max_allowed_wait_time = 20.minutes # Across multiple instances of this job for a
    # given hash we would wait only for this time for it to mined

  end

  #
  # * Author: Puneet
  # * Date: 01/02/2018
  # * Reviewed By:
  #
  # @return [Result::Base]
  #
  def validate

    @client_setup_activity_log = ClientSetupActivityLog.where(id: @client_setup_activity_log_id).first

    return error_with_data(
        'j_s_gttssj_1',
        'Client Setup Log Not Found.',
        'Client Setup Log Not Found.',
        GlobalConstant::ErrorAction.default,
        {}
    ) if @client_setup_activity_log.blank?

  end

end
