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

    get_transaction_status

    check_transfer_done

    check_and_enqueue_job

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
    @critical_log_id = params[:critical_log_id]
    @stake_params = params[:stake_params]
    @started_job_at = params[:started_job_at]

    @critical_chain_interaction_log_obj = nil
    @transfer_done = false
    @service_response_data = {}

    @max_allowed_wait_time = 30.minutes

  end

  #
  # * Author: Puneet
  # * Date: 01/02/2018
  # * Reviewed By:
  #
  # @return [Result::Base]
  #
  def validate

    @critical_chain_interaction_log_obj = CriticalChainInteractionLog.where(id: @critical_log_id).first

    return error_with_data(
        'j_s_gttssj_1',
        'Client Setup Log Not Found.',
        'Client Setup Log Not Found.',
        GlobalConstant::ErrorAction.default,
        {}
    ) if @critical_chain_interaction_log_obj.blank?

    @started_job_at ||= @critical_chain_interaction_log_obj.created_at.to_i

  end

  # Get status and validate transfer transaction hash.
  #
  # * Author: Kedar
  # * Date: 17/02/2018
  # * Reviewed By:
  #
  def get_transaction_status

    return success if @critical_chain_interaction_log_obj.status == GlobalConstant::CriticalChainInteractions.processed_status

    r = SaasApi::Transaction::GetReceipt.new.perform(
      {
        transaction_hash: @transaction_hash,
        chain: 'value'
      }
    )

    @critical_chain_interaction_log_obj.debug_data = r
    if r.success?
      @critical_chain_interaction_log_obj.status = GlobalConstant::CriticalChainInteractions.pending_status
    else
      @critical_chain_interaction_log_obj.status = GlobalConstant::CriticalChainInteractions.failed_status
    end
    @critical_chain_interaction_log_obj.save!

    return r unless r.success?

    @service_response_data = r.data

    success

  end

  def check_transfer_done
    #@service_response_data
    @transfer_done = true
  end

  def check_propose_done
    propose_log_id = @critical_chain_interaction_log_obj.parent_id
    return true unless propose_log_id
    propose_log_obj = CriticalChainInteractionLog.where(id: propose_log_id).first
    propose_log_obj.status == GlobalConstant::CriticalChainInteractions.processed_status
  end

  # Enqueue job
  #
  # * Author: Alpesh
  # * Date: 17/02/2018
  # * Reviewed By:
  #
  def check_and_enqueue_job

    if @transfer_done && check_propose_done

      @critical_chain_interaction_log_obj.status = GlobalConstant::CriticalChainInteractions.processed_status
      @critical_chain_interaction_log_obj.save!

      # entry in critical chain log for approve job
      start_approve_job

    elsif Time.now.to_i - @started_job_at > @max_allowed_wait_time

      @critical_chain_interaction_log_obj.status = GlobalConstant::CriticalChainInteractions.timeout_status
      @critical_chain_interaction_log_obj.save!
      return

    else

      BgJob.enqueue(
        Stake::GetTransferToStakerStatusJob,
        {
          critical_log_id: critical_log_obj.id,
          transaction_hash: @transaction_hash,
          started_job_at: @started_job_at,
          stake_params: @stake_params
        },
        {
          wait: 30.seconds
        }
      )

    end

  end

  # Start approve job.
  #
  # * Author: Alpesh
  # * Date: 17/02/2018
  # * Reviewed By:
  #
  def start_approve_job
    critical_log_obj = CriticalChainInteractionLog.create!(
      {
        parent_id: @critical_chain_interaction_log_obj.id,
        client_id: @critical_chain_interaction_log_obj.client_id,
        client_token_id: @critical_chain_interaction_log_obj.client_token_id,
        activity_type: GlobalConstant::CriticalChainInteractions.stake_approval_started_activity_type,
        status: GlobalConstant::CriticalChainInteractions.queued_status
      }
    )

    BgJob.enqueue(
      Stake::ApproveJob,
      {
        critical_log_id: critical_log_obj.id,
        started_job_at: Time.now.to_i,
        stake_params: @stake_params
      }
    )
  end

end
