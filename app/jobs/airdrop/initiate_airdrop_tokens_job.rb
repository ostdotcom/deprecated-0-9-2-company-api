class Airdrop::InitiateAirdropTokensJob < ApplicationJob

  include Util::ResultHelper

  queue_as GlobalConstant::Sidekiq.queue_name :default_medium_priority_queue

  # This job would be called after stake and mint.
  # Airdrop would only be initiated after all above processes are complete.

  # Perform
  #
  # * Author: Pankaj
  # * Date: 26/02/2018
  # * Reviewed By:
  #
  # @param [Integer] parent_critical_log_id (mandatory) - id of ClientChainInteraction of parent
  # @param [Integer] client_id (mandatory) - id of client who want to start Airdrop
  # @param [Integer] client_token_id (mandatory) - client token id
  # @param [Integer] amount (mandatory) - Amount to airdrop in Branded token base unit.
  # @param [String] airdrop_list_type (mandatory) - List type of users to airdrop eg: all or new
  #
  def perform(params)

    init_params(params)

    validate_siblings_jobs_complete

    if @siblings_process_complete
      r = start_airdrop
      return error_with_data(
          'j_a_iatj_1',
          'Could not initiate airdrop task.',
          'Could not initiate airdrop task.',
          GlobalConstant::ErrorAction.default,
          {}
      ) unless r.success?
    elsif @sibling_process_failed
      return error_with_data(
          'j_a_iatj_2',
          'Could not initiate airdrop task.',
          'Could not initiate airdrop task.',
          GlobalConstant::ErrorAction.default,
          {}
      )
    else
      enqueue_self
    end

    success

  end

  private

  # init params
  #
  # * Author: Pankaj
  # * Date: 26/02/2018
  # * Reviewed By:
  #
  def init_params(params)
    @parent_critical_log_id = params[:parent_critical_log_id]
    @client_token_id = params[:client_token_id]
    @client_id = params[:client_id]
    @amount = params[:amount]
    @airdrop_list_type = params[:airdrop_list_type]

    @siblings_process_complete = false
    @sibling_process_failed = false

  end

  # Validate all siblings processes are complete then only start airdrop transfers.
  #
  # * Author: Pankaj
  # * Date: 26/02/2018
  # * Reviewed By:
  #
  def validate_siblings_jobs_complete
    chain_logs = CacheManagement::CriticalChainInteractionStatus.new([@parent_critical_log_id]).fetch[@parent_critical_log_id]

    # If no siblings chain logs are present then don't initiate the airdrop process
    return if chain_logs.blank?

    # If any same parent chain logs are present then check whether all are processed or not.
    # If any chain log has status other than processed then don't start airdrop tokens.
    statuses = []

    # Extract self activity kind
    chain_logs.each do |x|
      if x[:activity_kind] != GlobalConstant::CriticalChainInteractions.airdrop_users_activity_type
        statuses << x[:status]
      end
    end
    @sibling_process_failed = statuses.include?(GlobalConstant::CriticalChainInteractions.failed_status)
    return if @sibling_process_failed

    return if (statuses - [GlobalConstant::CriticalChainInteractions.processed_status]).present?

    @siblings_process_complete = true
  end

  # Start Airdrop
  #
  # * Author: Pankaj
  # * Date: 26/02/2018
  # * Reviewed By:
  #
  def start_airdrop
    Economy::AirdropToUsers.new(parent_critical_log_id: @parent_critical_log_id,
                                client_token_id: @client_token_id,
                                client_id: @client_id,
                                amount: @amount,
                                airdrop_list_type: @airdrop_list_type).perform
  end

  # Enqueue job
  #
  # * Author: Pankaj
  # * Date: 26/02/2018
  # * Reviewed By:
  #
  def enqueue_self

    BgJob.enqueue(
      Airdrop::InitiateAirdropTokensJob,
      {
          parent_critical_log_id: @parent_critical_log_id,
          client_token_id: @client_token_id,
          client_id: @client_id,
          amount: @amount,
          airdrop_list_type: @airdrop_list_type
      },
      {
        wait: 10.seconds
      }
    )

  end

end
