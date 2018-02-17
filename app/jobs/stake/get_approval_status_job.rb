class Stake::GetApprovalStatusJob < ApplicationJob

  include Util::ResultHelper

  queue_as GlobalConstant::Sidekiq.queue_name :default_medium_priority_queue

  # Perform
  #
  # * Author: Kedar
  # * Date: 29/01/2018
  # * Reviewed By:
  #
  # @param [String] transation_hash (mandatory) - transaction hash of the approval transaction
  # @param [Hash] stake_params (mandatory) - Stake params
  #
  def perform(params)

    init_params(params)

    r = get_approval_status
    return unless r.success?

    check_and_enqueue_job

  end

  private

  # init params
  #
  # * Author: Kedar
  # * Date: 29/01/2018
  # * Reviewed By:
  #
  # @param [Hash] params
  #
  def init_params(params)

    @transaction_hash = params[:transaction_hash]
    @stake_params = params[:stake_params]
    @critical_log_id = params[:critical_log_id]
    @started_job_at = params[:started_job_at]

    @approval_done = false
    @max_allowed_wait_time = 30.minutes

  end

  # Get Approval Status
  #
  # * Author: Kedar
  # * Date: 29/01/2018
  # * Reviewed By:
  #
  # @return [Result::Base]
  #
  def get_approval_status
    params = {
      transaction_hash: @transaction_hash
    }

    @critical_chain_interaction_log_obj = CriticalChainInteractionLog.where(id: @critical_log_id).first

    r = SaasApi::Stake::GetApprovalStatus.new.perform(params)

    @critical_chain_interaction_log_obj.debug_data = r
    if r.success?
      @critical_chain_interaction_log_obj.status = GlobalConstant::CriticalChainInteractions.pending_status
    else
      @critical_chain_interaction_log_obj.status = GlobalConstant::CriticalChainInteractions.failed_status
    end
    @critical_chain_interaction_log_obj.save!

    return r unless r.success?

    @approval_done = true

    success
  end

  # Enqueue job
  #
  # * Author: Kedar
  # * Date: 29/01/2018
  # * Reviewed By:
  #
  def check_and_enqueue_job
    if approval_done?

      @critical_chain_interaction_log_obj.status = GlobalConstant::CriticalChainInteractions.processed_status
      @critical_chain_interaction_log_obj.save!

      start_stake_job

    elsif Time.now.to_i - @started_job_at > @max_run_time_delta

      @critical_chain_interaction_log_obj.status = GlobalConstant::CriticalChainInteractions.timeout_status
      @critical_chain_interaction_log_obj.save!
      return

    else

      BgJob.enqueue(
        Stake::GetApprovalStatusJob,
        {
          critical_log_id: @critical_log_id,
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

  def start_stake_job

    critical_log_obj = CriticalChainInteractionLog.create!(
      {
        parent_id: @critical_chain_interaction_log_obj.parent_id,
        client_id: @critical_chain_interaction_log_obj.client_id,
        client_token_id: @critical_chain_interaction_log_obj.client_token_id,
        activity_type: GlobalConstant::CriticalChainInteractions.stake_started_activity_type,
        status: GlobalConstant::CriticalChainInteractions.queued_status
      }
    )

    BgJob.enqueue(
      Stake::StartJob,
      {
        critical_log_obj: critical_log_obj.id,
        started_job_at: Time.now.to_i,
        stake_params: @stake_params
      }
    )

  end

  # Is approval done
  #
  # * Author: Kedar
  # * Date: 24/01/2018
  # * Reviewed By:
  #
  # @return [Boolean]
  #
  def approval_done?
    @approval_done
  end

end
