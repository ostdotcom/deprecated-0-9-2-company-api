class Airdrop::GetAirdropTransactionStatusJob < ApplicationJob

  include Util::ResultHelper

  queue_as GlobalConstant::Sidekiq.queue_name :default_medium_priority_queue

  # Perform
  #
  # * Author: Pankaj
  # * Date: 22/02/2018
  # * Reviewed By:
  #
  # @param [Integer] critical_log_id (mandatory) - id of ClientChainInteraction
  #
  def perform(params)

    init_params(params)

    r = validate
    return r unless r.success?

    r = get_airdrop_status
    return unless r.success?

    enqueue_self if @critical_chain_interaction_log.is_pending?

    success

  end

  private

  # init params
  #
  # * Author: Pankaj
  # * Date: 22/02/2018
  # * Reviewed By:
  #
  def init_params(params)
    @critical_log_id = params[:critical_log_id]

    @critical_chain_interaction_log = nil
    @transaction_uuid = nil

  end

  # Validate params
  #
  # * Author: Pankaj
  # * Date: 22/02/2018
  # * Reviewed By:
  #
  # Sets @critical_chain_interaction_log
  #
  # @return [Result::Base]
  #
  def validate

    @critical_chain_interaction_log = CriticalChainInteractionLog.where(id: @critical_log_id).first

    return error_with_data(
      'j_a_gatsj_1',
      'Critical chain interation log id not found.',
      'Critical chain interation log id not found.',
      GlobalConstant::ErrorAction.default,
      {}
    ) if @critical_chain_interaction_log.blank?

    @transaction_uuid = @critical_chain_interaction_log.transaction_uuid

    success
  end

  # Get Airdrop Transaction Status
  #
  # * Author: Pankaj
  # * Date: 22/02/2018
  # * Reviewed By:
  #
  # @return [Result::Base]
  #
  def get_airdrop_status
    # Airdrop job is already processed.
    return success if @critical_chain_interaction_log.is_processed?

    r = make_saas_call

    if @critical_chain_interaction_log.can_be_marked_timeout?
      # Timeout
      @critical_chain_interaction_log.status = GlobalConstant::CriticalChainInteractions.timeout_status
    elsif !r.success?
      # failed - service failure
      @critical_chain_interaction_log.status = GlobalConstant::CriticalChainInteractions.failed_status
    else
      # If current status is complete then mark as processed.
      if r.data["current_status"] == 'complete'
        # processed
        @critical_chain_interaction_log.status = GlobalConstant::CriticalChainInteractions.processed_status
      elsif r.data["current_status"] == 'failed'
        # Failed
        @critical_chain_interaction_log.status = GlobalConstant::CriticalChainInteractions.failed_status
      else
        # pending
        @critical_chain_interaction_log.status = GlobalConstant::CriticalChainInteractions.pending_status
      end
    end

    @critical_chain_interaction_log.response_data = r.to_hash
    @critical_chain_interaction_log.save!

    if @critical_chain_interaction_log.is_pending? || @critical_chain_interaction_log.is_processed?
      return success
    else
      return error_with_data(
        'j_a_gatsj_2',
        'Could not find airdrop status.',
        'Could not find airdrop status.',
        GlobalConstant::ErrorAction.default,
        {}
      )
    end

    success
  end

  # Make Saas Api call
  #
  # * Author: Pankaj
  # * Date: 22/02/2018
  # * Reviewed By:
  #
  #
  # @return [Result::Base]
  #
  def make_saas_call

    result = CacheManagement::ClientApiCredentials.new([@critical_chain_interaction_log.client_id]).
        fetch[@critical_chain_interaction_log.client_id]
    return error_with_data(
        'j_a_gatsj_3',
        "Invalid client.",
        'Something Went Wrong.',
        GlobalConstant::ErrorAction.default,
        {}
    ) if result.blank?

    # Create OST Sdk Obj
    credentials = OSTSdk::Util::APICredentials.new(result[:api_key], result[:api_secret])
    @ost_sdk_obj = OSTSdk::Saas::Users.new(GlobalConstant::Base.sub_env, credentials)

    service_response = @ost_sdk_obj.get_airdrop_status(airdrop_uuid: @transaction_uuid)

    service_response

  end

  # Enqueue job
  #
  # * Author: Pankaj
  # * Date: 22/02/2018
  # * Reviewed By:
  #
  def enqueue_self

    BgJob.enqueue(
      Airdrop::GetAirdropTransactionStatusJob,
      {
        critical_log_id: @critical_log_id
      },
      {
        wait: 10.seconds
      }
    )

  end

end
