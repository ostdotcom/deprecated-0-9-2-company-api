class StakeAndMint::GetStakeStatusJob < ApplicationJob

  include Util::ResultHelper

  queue_as GlobalConstant::Sidekiq.queue_name :default_medium_priority_queue

  # Perform
  #
  # * Author: Puneet
  # * Date: 01/02/2018
  # * Reviewed By: Sunil
  #
  # @param [Integer] critical_log_id (mandatory) - id of ClientChainInteraction
  # @param [Integer] parent_id (mandatory) - parent id of next tasks in chain
  # @param [Decimal] existing_balance (mandatory) - existing balance of beneficiary
  #
  # @return [Result::Base]
  #
  def perform(params)

    init_params(params)

    r = validate_and_sanitize
    return r unless r.success?

    r = get_stake_and_mint_status
    return r unless r.success?

    if @critical_chain_interaction_log.is_pending?
      enqueue_self
    end

    success
  end

  private

  # Initialize params
  #
  # * Author: Puneet
  # * Date: 01/02/2018
  # * Reviewed By: Sunil
  #
  def init_params(params)

    @critical_log_id = params[:critical_log_id]
    @parent_id = params[:parent_id]
    @existing_balance = params[:existing_balance]

    @critical_chain_interaction_log = nil

    @client_token = nil
  end

  # Validate params
  #
  # * Author: Puneet
  # * Date: 01/02/2018
  # * Reviewed By: Sunil
  #
  # Sets @critical_chain_interaction_log, @client_token
  #
  # @return [Result::Base]
  #
  def validate_and_sanitize

    @critical_chain_interaction_log = CriticalChainInteractionLog.where(id: @critical_log_id).first

    return error_with_data(
        'j_s_gssj_1',
        'Critical chain interation log id not found.',
        'Critical chain interation log id not found.',
        GlobalConstant::ErrorAction.default,
        {}
    ) if @critical_chain_interaction_log.blank?

    @client_token = ClientToken.where(id: @critical_chain_interaction_log.client_token_id).first

    success
  end

  # Get Stake and mint status
  #
  # * Author: Kedar
  # * Date: 29/01/2018
  # * Reviewed By: Sunil
  #
  def get_stake_and_mint_status

    @client_token_s = CacheManagement::ClientTokenSecure.new([@client_token.id]).fetch[@client_token.id]

    r = FetchClientBalances.new(
        client_id: @client_token.client_id,
        balances_to_fetch: {
            GlobalConstant::CriticalChainInteractions.utility_chain_type => {
                address_uuid: @client_token_s[:reserve_uuid],
                balance_types: [
                    GlobalConstant::BalanceTypes.ost_prime_balance_type,
                    @client_token.symbol
                ]
            }
        }
    ).perform

    if @critical_chain_interaction_log.can_be_marked_timeout?
      # Timeout
      @critical_chain_interaction_log.status = GlobalConstant::CriticalChainInteractions.timeout_status
    elsif !r.success? || !r.data.present?
      # failed - service failure
      @critical_chain_interaction_log.status = GlobalConstant::CriticalChainInteractions.failed_status
    else

      @client_balances = r.data['balances']

      if @critical_chain_interaction_log.activity_type == GlobalConstant::CriticalChainInteractions.stake_bt_started_activity_type
        new_balance = @client_balances[@client_token[:symbol]].to_f
      else
        new_balance = @client_balances[GlobalConstant::BalanceTypes.ost_prime_balance_type].to_f
      end

      if new_balance > @existing_balance.to_f
        # processed
        @critical_chain_interaction_log.status = GlobalConstant::CriticalChainInteractions.processed_status
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
        'j_s_gssj_2',
        'Stake and mint failed.',
        'Stake and mint failed.',
        GlobalConstant::ErrorAction.default,
        {}
      )
    end

  end

  # Enqueue job
  #
  # * Author: Alpesh
  # * Date: 17/02/2018
  # * Reviewed By: Sunil
  #
  def enqueue_self
    BgJob.enqueue(
      StakeAndMint::GetStakeStatusJob,
      {
        critical_log_id: @critical_log_id,
        parent_id: @parent_id,
        existing_balance: @existing_balance
      },
      {
        wait: 10.seconds
      }
    )
  end

end
