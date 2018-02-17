class Stake::ApproveJob < ApplicationJob

  include Util::ResultHelper

  queue_as GlobalConstant::Sidekiq.queue_name :default_medium_priority_queue

  # Perform
  #
  # * Author: Kedar
  # * Date: 29/01/2018
  # * Reviewed By:
  #
  # @param [Hash] stake_params (mandatory) - Stake params
  #
  def perform(params)

    init_params(params)

    r = approve
    return unless r.success?

    Rails.logger.info("approve initiated with transaction hash:: #{@transaction_hash}")

    update_critical_log

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
    @stake_params = params[:stake_params]
    @critical_log_id = params[:critical_log_id]
    @started_job_at = params[:started_job_at]

    @transaction_hash = nil
    @transaction_uuid = nil

  end

  # Approve
  #
  # * Author: Kedar
  # * Date: 24/01/2018
  # * Reviewed By:
  #
  # @return [Result::Base]
  #
  def approve
    @critical_chain_interaction_log_obj = CriticalChainInteractionLog.where(id: @critical_log_id).first

    r = SaasApi::Stake::Approve.new.perform({})

    @critical_chain_interaction_log_obj.debug_data = r
    @critical_chain_interaction_log_obj.status = GlobalConstant::CriticalChainInteractions.failed_status
    @critical_chain_interaction_log_obj.save!

    return r unless r.success?
    @transaction_hash = r.data[:transaction_hash]
    @transaction_uuid = r.data[:transaction_uuid]

    success
  end

  # Update Critical log.
  #
  # * Author: Alpesh
  # * Date: 17/02/2018
  # * Reviewed By:
  #
  def update_critical_log
    @critical_chain_interaction_log_obj.transaction_hash = @transaction_hash
    @critical_chain_interaction_log_obj.transaction_uuid = @transaction_uuid
    @critical_chain_interaction_log_obj.status = GlobalConstant::CriticalChainInteractions.pending_status
    @critical_chain_interaction_log_obj.save!
  end

  # Enqueue job
  #
  # * Author: Kedar
  # * Date: 24/01/2018
  # * Reviewed By:
  #
  def check_and_enqueue_job

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
