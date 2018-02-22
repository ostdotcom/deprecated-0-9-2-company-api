class Airdrop::GetAirdropDeployStatusJob < ApplicationJob

  include Util::ResultHelper

  queue_as GlobalConstant::Sidekiq.queue_name :default_medium_priority_queue

  # Perform
  #
  # * Author: Kedar
  # * Date: 29/01/2018
  # * Reviewed By: Sunil
  #
  # @param [Integer] critical_log_id (mandatory) - id of ClientChainInteraction
  # @param [Integer] parent_id (mandatory) - parent id of next tasks in chain
  #
  def perform(params)

    init_params(params)

    r = validate
    return r unless r.success?

    r = get_airdrop_deploy_status
    return unless r.success?

    if @critical_chain_interaction_log.is_processed?

      # workers.setWorker
      # airdrop.setPriceOracle
      # airdrop.setAcceptedMargin

      Rails.logger.debug("---------------------- Completed airdrop... start 3 new Jobs here.")

    else
      enqueue_self
    end

    success

  end

  private

  # init params
  #
  # * Author: Kedar
  # * Date: 29/01/2018
  # * Reviewed By: Sunil
  #
  def init_params(params)
    @critical_log_id = params[:critical_log_id]
    @parent_id = params[:parent_id]

    @critical_chain_interaction_log = nil
    @transaction_hash = nil

  end

  # Validate params
  #
  # * Author: Puneet
  # * Date: 01/02/2018
  # * Reviewed By: Sunil
  #
  # Sets @critical_chain_interaction_log, @transaction_hash , @client_token
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

    @transaction_hash = @critical_chain_interaction_log.transaction_hash

    success
  end

  # Get Airdrop deploy Status
  #
  # * Author: Alpesh
  # * Date: 21/02/2018
  # * Reviewed By:
  #
  # @return [Result::Base]
  #
  def get_airdrop_deploy_status
    # Initial transfer transaction is done
    return success if @critical_chain_interaction_log.is_processed?

    r = SaasApi::StakeAndMint::GetReceipt.new.perform(
      {
        transaction_hash: @transaction_hash,
        chain: GlobalConstant::CriticalChainInteractions.utility_chain_type
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
        # processed
        @critical_chain_interaction_log.status = GlobalConstant::CriticalChainInteractions.processed_status
        update_airdrop_contract_address(r.data["formattedTransactionReceipt"]["contractAddress"])
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
  # * Author: Kedar
  # * Date: 29/01/2018
  # * Reviewed By: Sunil
  #
  def enqueue_self

    BgJob.enqueue(
      Airdrop::GetAirdropDeployStatusJob,
      {
        critical_log_id: @critical_log_id,
        parent_id: @parent_id
      },
      {
        wait: 10.seconds
      }
    )

  end

  # update contract address.
  #
  # * Author: Kedar
  # * Date: 29/01/2018
  # * Reviewed By: Sunil
  #
  def update_airdrop_contract_address(contract_address)

    client_token = ClientToken.where(id: @critical_chain_interaction_log.client_token_id).first
    ClientToken.where(id: @critical_chain_interaction_log.client_token_id).
      update_all(airdrop_contract_addr: contract_address)

    SaasApi::OnBoarding::EditBt.new.perform(
      symbol: client_token.symbol,
      client_id: client_token.client_id,
      airdrop_contract_addr: contract_address
    )

  end

end
