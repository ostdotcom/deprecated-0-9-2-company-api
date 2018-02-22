class StakeAndMint::GetApprovalStatusJob < ApplicationJob

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

    r = get_approval_status
    return unless r.success?

    if @critical_chain_interaction_log.is_processed?

      r = get_client_balances
      return r unless r.success?

      start_stake_st_prime_job if @st_prime_to_mint > 0
      start_stake_bt_job if @bt_to_mint > 0
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
    @bt_to_mint = nil
    @st_prime_to_mint = nil

    @existing_st_prime_balance = nil
    @existing_bt_balance = nil

    @client_token = nil
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
    @bt_to_mint = @critical_chain_interaction_log.request_params[:bt_to_mint].to_f
    @st_prime_to_mint = @critical_chain_interaction_log.request_params[:st_prime_to_mint].to_f

    @client_token = ClientToken.where(id: @critical_chain_interaction_log.client_token_id).first

    success
  end

  # Get Approval Status
  #
  # * Author: Kedar
  # * Date: 29/01/2018
  # * Reviewed By: Sunil
  #
  # @return [Result::Base]
  #
  def get_approval_status
    # Initial transfer transaction is done
    return success if @critical_chain_interaction_log.is_processed?

    r = SaasApi::StakeAndMint::GetReceipt.new.perform(
      {
        transaction_hash: @transaction_hash,
        chain: GlobalConstant::CriticalChainInteractions.value_chain_type
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

  # Get client balances
  #
  # * Author: Kedar
  # * Date: 29/01/2018
  # * Reviewed By: Sunil
  #
  def get_client_balances

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

    if !r.success?
      @critical_chain_interaction_log.status = GlobalConstant::CriticalChainInteractions.failed_status
      @critical_chain_interaction_log.response_data = r.to_hash
      @critical_chain_interaction_log.save!
      return r
    end

    @client_balances = r.data['balances']

    @existing_st_prime_balance = @client_balances[GlobalConstant::BalanceTypes.ost_prime_balance_type]
    @existing_bt_balance = @client_balances[@client_token[:symbol]]

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
      StakeAndMint::GetApprovalStatusJob,
      {
        critical_log_id: @critical_log_id,
        parent_id: @parent_id
      },
      {
        wait: 10.seconds
      }
    )

  end

  # Enqueue bt stake and mint job
  #
  # * Author: Kedar
  # * Date: 29/01/2018
  # * Reviewed By: Sunil
  #
  def start_stake_bt_job

    # convert bt into ost.
    ost_to_stake_amount = @bt_to_mint / @client_token.conversion_factor.to_f
    existing_balance = @existing_bt_balance

    params = {
      client_id: @critical_chain_interaction_log.client_id,
      token_symbol: @client_token.symbol,
      to_stake_amount: ost_to_stake_amount,
      bt_to_mint: @bt_to_mint
    }

    stake_response = SaasApi::StakeAndMint::StartBrandedToken.new.perform(params)

    if stake_response.success?
      status = GlobalConstant::CriticalChainInteractions.pending_status
      transaction_hash = stake_response.data[:transaction_hash]
      transaction_uuid = stake_response.data[:transaction_uuid]
    else
      status = GlobalConstant::CriticalChainInteractions.failed_status
    end

    critical_log_obj = CriticalChainInteractionLog.create!(
      {
        parent_id: @parent_id,
        client_id: @critical_chain_interaction_log.client_id,
        activity_type: GlobalConstant::CriticalChainInteractions.stake_bt_started_activity_type,
        client_token_id: @critical_chain_interaction_log.client_token_id,
        chain_type: GlobalConstant::CriticalChainInteractions.value_chain_type,
        transaction_uuid: transaction_uuid,
        transaction_hash: transaction_hash,
        request_params: params,
        response_data: stake_response.to_hash,
        status: status
      }
    )

    BgJob.enqueue(
      StakeAndMint::GetStakeStatusJob,
      {
        critical_log_id: critical_log_obj.id,
        parent_id: @parent_id,
        existing_balance: existing_balance
      },
      {
        wait: 10.seconds
      }
    ) if critical_log_obj.is_pending?

  end

  # Enqueue st' stake and mint job
  #
  # * Author: Kedar
  # * Date: 29/01/2018
  # * Reviewed By: Sunil
  #
  def start_stake_st_prime_job

    # convert st' into ost.
    st_prime_to_stake_amount = @st_prime_to_mint
    existing_balance = @existing_st_prime_balance

    params = {
      client_id: @critical_chain_interaction_log.client_id,
      to_stake_amount: st_prime_to_stake_amount,
    }

    stake_response = SaasApi::StakeAndMint::StartStPrime.new.perform(params)

    if stake_response.success?
      status = GlobalConstant::CriticalChainInteractions.pending_status
      transaction_hash = stake_response.data[:transaction_hash]
      transaction_uuid = stake_response.data[:transaction_uuid]
    else
      status = GlobalConstant::CriticalChainInteractions.failed_status
    end

    critical_log_obj = CriticalChainInteractionLog.create!(
      {
        parent_id: @parent_id,
        client_id: @critical_chain_interaction_log.client_id,
        activity_type: GlobalConstant::CriticalChainInteractions.stake_st_prime_started_activity_type,
        client_token_id: @critical_chain_interaction_log.client_token_id,
        chain_type: GlobalConstant::CriticalChainInteractions.value_chain_type,
        transaction_uuid: transaction_uuid,
        transaction_hash: transaction_hash,
        request_params: params,
        response_data: stake_response.to_hash,
        status: status
      }
    )

    BgJob.enqueue(
      StakeAndMint::GetStakeStatusJob,
      {
        critical_log_id: critical_log_obj.id,
        parent_id: @parent_id,
        existing_balance: existing_balance
      },
      {
        wait: 10.seconds
      }
    ) if critical_log_obj.is_pending?

  end


end
