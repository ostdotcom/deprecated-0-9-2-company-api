class Airdrop::AirdropWorkersSetupStatusJob < ApplicationJob

  include Util::ResultHelper

  queue_as GlobalConstant::Sidekiq.queue_name :default_medium_priority_queue

  # Perform
  #
  # * Author: Pankaj
  # * Date: 22/03/2018
  # * Reviewed By:
  #
  # @param [Integer] critical_log_id (mandatory) - id of ClientChainInteraction
  #
  def perform(params)

    init_params(params)

    r = validate
    return r unless r.success?

    r = get_airdrop_worker_setup_status
    return unless r.success?

    if @critical_chain_interaction_log.is_pending?
      enqueue_self
    else
      set_airdrop_setup_done
    end

    success

  end

  private

  # init params
  #
  # * Author: Pankaj
  # * Date: 22/03/2018
  # * Reviewed By:
  #
  def init_params(params)
    @critical_log_id = params[:critical_log_id]

    @critical_chain_interaction_log = nil
    @transaction_hash_records = nil

  end

  # Validate params
  #
  # * Author: Pankaj
  # * Date: 22/03/2018
  # * Reviewed By:
  #
  # Sets @critical_chain_interaction_log, @transaction_hash
  #
  # @return [Result::Base]
  #
  def validate

    @critical_chain_interaction_log = CriticalChainInteractionLog.where(id: @critical_log_id).first

    return error_with_data(
      'j_s_gasj_1',
      'Critical chain interation log id not found.',
      'Critical chain interation log id not found.',
      GlobalConstant::ErrorAction.default,
      {}
    ) if @critical_chain_interaction_log.blank?

    @transaction_hash_records = @critical_chain_interaction_log.response_data['data']

    success
  end

  # Get Airdrop deploy Status
  #
  # * Author: Pankaj
  # * Date: 22/03/2018
  # * Reviewed By:
  #
  # @return [Result::Base]
  #
  def get_airdrop_worker_setup_status
    # Initial transfer transaction is done
    return success if @critical_chain_interaction_log.is_processed?

    r = SaasApi::StakeAndMint::FetchWorkerStatus.new.perform(
      {
          transaction_records: @transaction_hash_records
      }
    )

    if @critical_chain_interaction_log.can_be_marked_timeout?
      # Timeout
      @critical_chain_interaction_log.status = GlobalConstant::CriticalChainInteractions.timeout_status
    elsif !r.success?
      # failed - service failure
      @critical_chain_interaction_log.status = GlobalConstant::CriticalChainInteractions.failed_status
    else
      # r.data will be blank when transaction is yet not mined.
      if r.data.present?
        is_complete = false
        # Assuming if one worker is set up properly then client can do transactions.
        # So mark this step as complete.
        r.data.each_value do |value|
          is_complete = (value['status'] == 'complete')
        end
        # processed
        @critical_chain_interaction_log.status = is_complete ? GlobalConstant::CriticalChainInteractions.processed_status :
                                                     GlobalConstant::CriticalChainInteractions.pending_status
      end
    end

    @critical_chain_interaction_log.response_data = r.to_hash
    @critical_chain_interaction_log.save!

    if @critical_chain_interaction_log.is_pending? || @critical_chain_interaction_log.is_processed?
      return success
    else
      return error_with_data(
        'j_s_gasj_2',
        'Transaction receipt failed.',
        'Transaction receipt failed.',
        GlobalConstant::ErrorAction.default,
        {}
      )
    end

    success
  end

  # Enqueue job
  #
  # * Author: Pankaj
  # * Date: 22/03/2018
  # * Reviewed By:
  #
  def enqueue_self

    BgJob.enqueue(
      Airdrop::AirdropWorkersSetupStatusJob,
      {
        critical_log_id: @critical_log_id
      },
      {
        wait: 10.seconds
      }
    )

  end

  def set_airdrop_setup_done
    processed_post_airdrop_steps = CriticalChainInteractionLog.
      where(client_token_id: @critical_chain_interaction_log.client_token_id).
      where("activity_type in (?)",
            [
              CriticalChainInteractionLog::activity_types[GlobalConstant::CriticalChainInteractions.set_worker_activity_type.to_sym],
              CriticalChainInteractionLog::activity_types[GlobalConstant::CriticalChainInteractions.set_price_oracle_activity_type],
              CriticalChainInteractionLog::activity_types[GlobalConstant::CriticalChainInteractions.set_accepted_margin_activity_type]
            ]).
      where(status: GlobalConstant::CriticalChainInteractions.processed_status).
      count

    if processed_post_airdrop_steps == 3
      client_token = ClientToken.where(id: @critical_chain_interaction_log.client_token_id).first
      client_token.send("set_#{GlobalConstant::ClientToken.airdrop_done_setup_step}")
      CacheManagement::ClientToken.new([@critical_chain_interaction_log.client_token_id]).clear
      client_token.save!
    end
  end

end
