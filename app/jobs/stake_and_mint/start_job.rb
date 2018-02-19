class Stake::StartJob < ApplicationJob

  include Util::ResultHelper

  queue_as GlobalConstant::Sidekiq.queue_name :default_medium_priority_queue

  # Perform
  #
  # * Author: Kedar
  # * Date: 29/01/2018
  # * Reviewed By:
  #
  # @param [String] beneficiary (mandatory) - eth address of the beneficiary
  # @param [Number] to_stake_amount (mandatory) - this is the amount of OST to stake
  # @param [String] uuid (mandatory) - uuid of the token
  #
  def perform(params)

    init_params(params)

    r = start_stake
    return unless r.success?

    Rails.logger.info("staking started with transaction hash:: #{@transaction_hash}")

    update_critical_log

  end

  private

  # init params
  #
  # * Author: Kedar
  # * Date: 24/01/2018
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

  # Start stake
  #
  # * Author: Kedar
  # * Date: 24/01/2018
  # * Reviewed By:
  #
  # @return [Result::Base]
  #
  def start_stake
    params = {
      beneficiary: @stake_params[:beneficiary],
      to_stake_amount: @stake_params[:to_stake_amount],
      uuid: @stake_params[:uuid]
    }

    @critical_chain_interaction_log_obj = CriticalChainInteractionLog.where(id: @critical_log_id).first

    r = SaasApi::StakeAndMint::Start.new.perform(params)

    @critical_chain_interaction_log_obj.response_data = r
    @critical_chain_interaction_log_obj.status = GlobalConstant::CriticalChainInteractions.failed_status
    @critical_chain_interaction_log_obj.save!

    return r unless r.success?

    @transaction_hash =  r.data[:transaction_hash]
    @transaction_uuid = r.data[:transaction_uuid]

    Rails.logger.info "Stake transaction hash:: " + @transaction_hash

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

end
