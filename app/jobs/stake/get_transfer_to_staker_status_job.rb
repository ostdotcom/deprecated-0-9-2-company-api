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
  # @param [Integer] critical_chain_interaction_log_id (mandatory) - id of ClientChainInteraction
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
    @chain_interaction_log_id = params[:critical_chain_interaction_log_id]
    @started_at = params[:started_at]

    @chain_interaction_log = nil

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

    @chain_interaction_log = CriticalChainInteractionLog.where(id: @chain_interaction_log_id).first

    return error_with_data(
        'j_s_gttssj_1',
        'Client Setup Log Not Found.',
        'Client Setup Log Not Found.',
        GlobalConstant::ErrorAction.default,
        {}
    ) if @chain_interaction_log.blank?

  end

end
