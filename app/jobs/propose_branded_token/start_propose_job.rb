class ProposeBrandedToken::StartProposeJob < ApplicationJob

  include Util::ResultHelper

  queue_as GlobalConstant::Sidekiq.queue_name :default_medium_priority_queue

  # Perform
  #
  # * Author: Kedar
  # * Date: 24/01/2018
  # * Reviewed By: Sunil
  #
  # @param [Integer] critical_log_id (mandatory) - chain log id
  #
  def perform(params)

    init_params(params)

    r = validate_and_sanitize
    return unless r.success?

    r = propose
    return unless r.success?

    # enqueue the get registration status job
    enqueue_job

  end

  private

  # init params
  #
  # * Author: Kedar
  # * Date: 24/01/2018
  # * Reviewed By: Sunil
  #
  # @param [Hash] params
  #
  def init_params(params)
    @critical_log_id = params[:critical_log_id]
    @parent_id = params[:parent_id]

    @critical_chain_interaction_log = nil

    @client_id = nil
    @client_token_id = nil
    @token_name = nil
    @token_symbol = nil
    @token_conversion_factor = nil

    @client_token = nil
  end

  # Validate and sanitize params
  #
  # * Author: Puneet
  # * Date: 01/02/2018
  # * Reviewed By: Sunil
  #
  # Sets @critical_chain_interaction_log, @client_id, @client_token_id, @client_token
  #
  # @return [Result::Base]
  #
  def validate_and_sanitize

    @critical_chain_interaction_log = CriticalChainInteractionLog.where(id: @critical_log_id).first

    return error_with_data(
      'j_s_gttssj_1',
      'Critical chain interation log id not found.',
      'Critical chain interation log id not found.',
      GlobalConstant::ErrorAction.default,
      {}
    ) if @critical_chain_interaction_log.blank?

    @client_id = @critical_chain_interaction_log.client_id
    @client_token_id = @critical_chain_interaction_log.client_token_id
    @token_name = @critical_chain_interaction_log.request_params[:token_name]
    @token_symbol = @critical_chain_interaction_log.request_params[:token_symbol]
    @token_conversion_factor = BigDecimal.new(@critical_chain_interaction_log.request_params[:token_conversion_factor])

    @client_token = ClientToken.where(id: @critical_chain_interaction_log.client_token_id).first

    return error_with_data(
      'grsj_2',
      'Propose not yet initiated.',
      'Propose not yet initiated.',
      GlobalConstant::ErrorAction.default,
      {}
    ) unless @client_token.propose_initiated?

    success
  end

  # Propose
  #
  # * Author: Kedar
  # * Date: 24/01/2018
  # * Reviewed By: Sunil
  #
  # @return [Result::Base]
  #
  def propose

    params = {
      token_symbol: @token_symbol,
      token_name: @token_name,
      token_conversion_factor: @token_conversion_factor
    }

    r = SaasApi::OnBoarding::ProposeBt.new.perform(params)

    if r.success?
      propose_status = GlobalConstant::CriticalChainInteractions.pending_status
      transaction_hash = r.data[:transaction_hash]
      transaction_uuid = r.data[:transaction_uuid]
    else
      propose_status = GlobalConstant::CriticalChainInteractions.failed_status
      transaction_hash = nil
      transaction_uuid = nil
      # Unset Propose initiated bit
      @client_token.send("unset_#{GlobalConstant::ClientToken.propose_initiated_setup_step}")
      @client_token.save
      CacheManagement::ClientToken.new([@client_token.id]).clear
    end

    @critical_chain_interaction_log.response_data = r.to_hash
    @critical_chain_interaction_log.transaction_hash = transaction_hash
    @critical_chain_interaction_log.transaction_uuid = transaction_uuid
    @critical_chain_interaction_log.status = propose_status
    @critical_chain_interaction_log.save!

    return r unless r.success?

    success

  end

  # Enqueue job
  #
  # * Author: Kedar
  # * Date: 24/01/2018
  # * Reviewed By: Sunil
  #
  def enqueue_job
    BgJob.enqueue(
      ProposeBrandedToken::GetProposeStatusJob,
      {
        critical_log_id: @critical_log_id,
        parent_id: @parent_id
      },
      {
        wait: 10.seconds
      }
    )
  end

end
