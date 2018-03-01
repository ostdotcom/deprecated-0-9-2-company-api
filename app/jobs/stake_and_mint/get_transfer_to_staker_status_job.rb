class StakeAndMint::GetTransferToStakerStatusJob < ApplicationJob

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
  #
  # @return [Result::Base]
  #
  def perform(params)

    init_params(params)

    r = validate_and_sanitize
    return r unless r.success?

    r = get_staker_transfer_status
    return r unless r.success?

    r = get_bt_proposal_status
    return r unless r.success?

    if @client_token.registration_done? && @critical_chain_interaction_log.is_processed?
      start_approve_job
    else
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

    @critical_chain_interaction_log = nil
    @transaction_hash = nil
    @st_prime_to_mint = nil

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
  def validate_and_sanitize

    @critical_chain_interaction_log = CriticalChainInteractionLog.where(id: @critical_log_id).first

    return error_with_data(
        'j_s_gttssj_1',
        'Critical chain interation log id not found.',
        'Critical chain interation log id not found.',
        GlobalConstant::ErrorAction.default,
        {}
    ) if @critical_chain_interaction_log.blank?

    @transaction_hash = @critical_chain_interaction_log.transaction_hash
    @st_prime_to_mint = @critical_chain_interaction_log.request_params[:st_prime_to_mint]

    @client_token = ClientToken.where(id: @critical_chain_interaction_log.client_token_id).first

    success

  end

  # Get status and validate staker transfer status.
  #
  # * Author: Kedar
  # * Date: 17/02/2018
  # * Reviewed By: Sunil
  #
  # @return [Result::Base]
  #
  def get_staker_transfer_status

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
        validate_tx_rsp = is_tx_data_valid?(r.data)
        if validate_tx_rsp.success?
          @critical_chain_interaction_log.status = GlobalConstant::CriticalChainInteractions.processed_status
        else
          @critical_chain_interaction_log.status = GlobalConstant::CriticalChainInteractions.failed_status
          r = validate_tx_rsp # in case of error we would log error in db and not tx receipt logs
        end
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
        'j_s_gttssj_2',
        'Transaction receipt failed.',
        'Transaction receipt failed.',
        GlobalConstant::ErrorAction.default,
        {}
      )
    end

  end

  # Get bt proposal status
  #
  # * Author: Kedar
  # * Date: 17/02/2018
  # * Reviewed By: Sunil
  #
  # @return [Result::Base]
  #
  def get_bt_proposal_status
    propose_log_id = @critical_chain_interaction_log.parent_id
    if !propose_log_id
      if @client_token.registration_done?
        return success
      else
        return error_with_data(
          'j_s_gttssj_3',
          'BT propose required.',
          'BT propose required.',
          GlobalConstant::ErrorAction.default,
          {}
        )
      end
    else
      propose_log_obj = CriticalChainInteractionLog.where(id: propose_log_id).first
      if propose_log_obj.is_pending? || propose_log_obj.is_processed?
        # re fetch token details
        @client_token = ClientToken.where(id: @critical_chain_interaction_log.client_token_id).first
        return success
      else
        return error_with_data(
          'j_s_gttssj_4',
          'BT propose failed.',
          'BT propose failed.',
          GlobalConstant::ErrorAction.default,
          {}
        )
      end
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
      StakeAndMint::GetTransferToStakerStatusJob,
      {
        critical_log_id: @critical_log_id,
        parent_id: @parent_id,
      },
      {
        wait: 10.seconds
      }
    )
  end

  # Start approve job.
  #
  # * Author: Alpesh
  # * Date: 17/02/2018
  # * Reviewed By: Sunil
  #
  def start_approve_job

    approve_response = SaasApi::StakeAndMint::Approve.new.perform({})

    if approve_response.success?
      status = GlobalConstant::CriticalChainInteractions.pending_status
      transaction_hash = approve_response.data[:transaction_hash]
      transaction_uuid = approve_response.data[:transaction_uuid]
    else
      status = GlobalConstant::CriticalChainInteractions.failed_status
    end

    critical_log_obj = CriticalChainInteractionLog.create!(
      {
        parent_id: @parent_id,
        client_id: @critical_chain_interaction_log.client_id,
        activity_type: GlobalConstant::CriticalChainInteractions.stake_approval_started_activity_type,
        client_token_id: @critical_chain_interaction_log.client_token_id,
        chain_type: GlobalConstant::CriticalChainInteractions.value_chain_type,
        transaction_uuid: transaction_uuid,
        transaction_hash: transaction_hash,
        request_params: @critical_chain_interaction_log.request_params,
        response_data: approve_response.to_hash,
        status: status
      }
    )

    BgJob.enqueue(
      StakeAndMint::GetApprovalStatusJob,
      {
        critical_log_id: critical_log_obj.id,
        parent_id: @parent_id
      },
      {
        wait: 10.seconds
      }
    ) if critical_log_obj.is_pending?

  end

  # Check if Tx Receipt is valid
  #
  # * Author: Puneet
  # * Date: 17/02/2018
  # * Reviewed By:
  #
  def is_tx_data_valid?(tx_receipt_data)

    r = SaasApi::OnBoarding::FetchChainInteractionParams.new.perform({client_id: @client_token[:client_id]})
    return r unless r.success?

    chain_interaction_params = r.data

    raw_receipt = tx_receipt_data['rawTransactionReceipt']

    client_address = ClientAddress.where(client_id: @client_token[:client_id]).last

    return error_with_data(
        'j_s_gttssj_5',
        'Invalid From Address.',
        'Invalid From Address.',
        GlobalConstant::ErrorAction.default,
        {}
    ) if client_address.blank? ||
        client_address.hashed_ethereum_address != LocalCipher.get_sha_hashed_text(raw_receipt['from'])

    return error_with_data(
        'j_s_gttssj_6',
        'Invalid To Address.',
        'Invalid To Address.',
        GlobalConstant::ErrorAction.default,
        {}
    ) if raw_receipt['to'].downcase != chain_interaction_params['simple_token_contract_addr'].downcase

    formatted_receipt = tx_receipt_data['formattedTransactionReceipt'] || {}

    buffer = formatted_receipt['eventsData'][0]['events'].select do |event|
      event['name'] == '_to'
    end

    return error_with_data(
        'j_s_gttssj_7',
        'Invalid Transfer To Address.',
        'Invalid Transfer To Address.',
        GlobalConstant::ErrorAction.default,
        {}
    ) if buffer.first['value'].downcase != chain_interaction_params['staker_addr'].downcase

    buffer = formatted_receipt['eventsData'][0]['events'].select do |event|
      event['name'] == '_value'
    end

    # IMP NOT:
    # Frontend is not able to handle converstion properly, so we don't trust the bt_to_mint amount from them
    # Let's recalculate it here. and use it for stake and mint
    transfered_ost = Util::Converter.from_wei_value(buffer.first['value'])
    ost_to_stake_to_mint_bt = transfered_ost - @st_prime_to_mint
    @critical_chain_interaction_log.request_params[:ost_to_stake_to_mint_bt] = ost_to_stake_to_mint_bt

    success

  end

end
