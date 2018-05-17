class RegisterBrandedToken::GetAirdropDeployStatusJob < ApplicationJob

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
        'something_went_wrong',
        GlobalConstant::ErrorAction.default
    ) if @critical_chain_interaction_log.is_failed?

    update_airdrop_contract_address

    if @critical_chain_interaction_log.is_pending?
      enqueue_self
    else
      enqueue_get_other_tasks_status_job
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
      'something_went_wrong',
      GlobalConstant::ErrorAction.default
    ) if @critical_chain_interaction_log.blank?

    @client_id = @critical_chain_interaction_log.client_id

    success

  end

  # update contract address.
  #
  # * Author: alpesh
  # * Date: 22/02/2018
  # * Reviewed By:
  #
  def update_airdrop_contract_address

    data = @critical_chain_interaction_log.response_data['data']
    return if data.blank? || data['transaction_receipt'].blank?

    contract_address = data['transaction_receipt']['contractAddress']

    return if contract_address.blank?

    ClientToken.where(id: @critical_chain_interaction_log.client_token_id).
        update_all(airdrop_contract_addr: contract_address)

    CacheManagement::ClientTokenSecure.new([@critical_chain_interaction_log.client_token_id]).clear

  end

  # Enqueue self
  #
  # * Author: alpesh
  # * Date: 22/02/2018
  # * Reviewed By:
  #
  def enqueue_self

    BgJob.enqueue(
      ::RegisterBrandedToken::GetAirdropDeployStatusJob,
      {
        parent_id: @parent_id
      },
      {
        wait: 10.seconds
      }
    )

  end

  # Enqueue verify other steps status job
  #
  # * Author: Puneet
  # * Date: 29/03/2018
  # * Reviewed By:
  #
  def enqueue_get_other_tasks_status_job

    BgJob.enqueue(
      ::RegisterBrandedToken::GetOtherTasksStatusJob,
      {
          parent_id: @parent_id
      },
      {
          wait: 30.seconds
      }
    )

  end

end
