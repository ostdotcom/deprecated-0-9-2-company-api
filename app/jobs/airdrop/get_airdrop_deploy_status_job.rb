class Airdrop::GetAirdropDeployStatusJob < ApplicationJob

  include Util::ResultHelper

  queue_as GlobalConstant::Sidekiq.queue_name :default_medium_priority_queue

  # Perform
  #
  # * Author: Kedar
  # * Date: 29/01/2018
  # * Reviewed By: Sunil
  #
  # @param [Integer] parent_id (mandatory) - parent id of next tasks in chain
  #
  def perform(params)

    init_params(params)

    r = validate
    return r unless r.success?

    return error_with_data(
        'j_s_gadsj_2',
        'Transaction receipt failed.',
        'Transaction receipt failed.',
        GlobalConstant::ErrorAction.default,
        {}
    ) if @critical_chain_interaction_log.is_failed?

    data = @critical_chain_interaction_log.response_data['data']

    update_airdrop_contract_address(data['transaction_receipt']['contractAddress'])

    if @critical_chain_interaction_log.is_pending?
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

    @parent_id = params[:parent_id]

    @critical_chain_interaction_log = nil
    @client_id = nil

  end

  # Validate params
  #
  # * Author: Puneet
  # * Date: 01/02/2018
  # * Reviewed By: Sunil
  #
  # Sets @critical_chain_interaction_log
  #
  # @return [Result::Base]
  #
  def validate

    @critical_chain_interaction_log = CriticalChainInteractionLog.where(
        parent_id: @parent_id,
        activity_type: GlobalConstant::CriticalChainInteractions.deploy_airdrop_activity_type
    ).first

    return error_with_data(
      'j_s_gasj_1',
      'Critical chain interation log id not found.',
      'Critical chain interation log id not found.',
      GlobalConstant::ErrorAction.default,
      {}
    ) if @critical_chain_interaction_log.blank?

    @client_id = @critical_chain_interaction_log.client_id

    success

  end

  # Enqueue job
  #
  # * Author: alpesh
  # * Date: 22/02/2018
  # * Reviewed By:
  #
  def enqueue_self

    BgJob.enqueue(
      Airdrop::GetAirdropDeployStatusJob,
      {
        parent_id: @parent_id
      },
      {
        wait: 10.seconds
      }
    )

  end

  # update contract address.
  #
  # * Author: alpesh
  # * Date: 22/02/2018
  # * Reviewed By:
  #
  def update_airdrop_contract_address(contract_address)

    return if contract_address.blank?

    ClientToken.where(id: @critical_chain_interaction_log.client_token_id).
      update_all(airdrop_contract_addr: contract_address)

    CacheManagement::ClientTokenSecure.new([@critical_chain_interaction_log.client_token_id]).clear

    # SaasApi::OnBoarding::EditBt.new.perform(
    #   symbol: client_token.symbol,
    #   client_id: client_token.client_id,
    #   airdrop_contract_addr: contract_address
    # )

  end

  # # set worker for a client
  # #
  # # * Author: alpesh
  # # * Date: 22/02/2018
  # # * Reviewed By:
  # #
  # def start_setops_airdrop
  #
  #   request_params = {
  #     client_id: @client_id,
  #     token_symbol: @client_token.symbol,
  #   }
  #
  #   saas_api_response = SaasApi::OnBoarding::SetopsAirdrop.new.perform(request_params)
  #
  #   process_saas_response(
  #     request_params,
  #     saas_api_response,
  #     GlobalConstant::CriticalChainInteractions.setops_airdrop_activity_type
  #   )
  #
  # end
  #
  # def process_saas_response(request_params, saas_api_response, activity_type)
  #
  #   if saas_api_response.success?
  #     status = GlobalConstant::CriticalChainInteractions.pending_status
  #     transaction_uuid = saas_api_response.data[:transaction_uuid]
  #     transaction_hash = saas_api_response.data[:transaction_hash]
  #   else
  #     status = GlobalConstant::CriticalChainInteractions.failed_status
  #   end
  #
  #   critical_log = CriticalChainInteractionLog.create!(
  #     {
  #       parent_id: @parent_id,
  #       client_id: @client_id,
  #       activity_type: activity_type,
  #       client_token_id: @critical_chain_interaction_log.client_token_id,
  #       chain_type: GlobalConstant::CriticalChainInteractions.utility_chain_type,
  #       transaction_uuid: transaction_uuid,
  #       transaction_hash: transaction_hash,
  #       request_params: request_params,
  #       response_data: saas_api_response.to_hash,
  #       status: status
  #     }
  #   )
  #
  #   BgJob.enqueue(
  #     Airdrop::SetopsAirdropStatusJob,
  #     {
  #       critical_log_id: critical_log.id,
  #       parent_id: @parent_id
  #     },
  #     {
  #       wait: 10.seconds
  #     }
  #   ) if critical_log.is_pending?
  # end

end
