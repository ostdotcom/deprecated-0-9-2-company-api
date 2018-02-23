class ProposeBrandedToken::GetProposeStatusJob < ApplicationJob

  include Util::ResultHelper

  queue_as GlobalConstant::Sidekiq.queue_name :default_medium_priority_queue

  # Perform
  #
  # * Author: Kedar
  # * Date: 24/01/2018
  # * Reviewed By: Sunil
  #
  # @param [Integer] critical_log_id (mandatory) - chain log id
  #
  def perform(params)

    puts("registration status start :: #{params.inspect}")

    init_params(params)

    r = validate_and_sanitize
    return unless r.success?

    r = get_registration_status
    return unless r.success?

    puts("registration status:: #{@registration_status.inspect}")

    if @critical_chain_interaction_log.is_pending?
      enqueue_self
    else
      deploy_airdrop_contract
    end

    success

  end

  private

  # init params
  #
  # * Author: Kedar
  # * Date: 24/01/2018
  # * Reviewed By: Sunil
  #
  # @param [Hash] params
  #
  def init_params(params)
    @critical_log_id = params[:critical_log_id]
    @parent_id = params[:parent_id]

    @critical_chain_interaction_log = nil
    @client_id = nil
    @client_token_id = nil
    @transaction_hash = nil

    @client_token = nil
    @registration_status = nil

  end

  # Validate and sanitize params
  #
  # * Author: Puneet
  # * Date: 01/02/2018
  # * Reviewed By: Sunil
  #
  # Sets @critical_chain_interaction_log, @client_id, @client_token_id, @transaction_hash, @client_token
  #
  # @return [Result::Base]
  #
  def validate_and_sanitize

    @critical_chain_interaction_log = CriticalChainInteractionLog.where(id: @critical_log_id).first

    return error_with_data(
      'j_s_grsj_1',
      'Critical chain interation log id not found.',
      'Critical chain interation log id not found.',
      GlobalConstant::ErrorAction.default,
      {}
    ) if @critical_chain_interaction_log.blank?

    @client_id = @critical_chain_interaction_log.client_id
    @client_token_id = @critical_chain_interaction_log.client_token_id
    @transaction_hash = @critical_chain_interaction_log.transaction_hash

    @client_token = ClientToken.where(id: @client_token_id).first

    success
  end

  # Get Registration Status
  #
  # * Author: Kedar
  # * Date: 24/01/2018
  # * Reviewed By: Sunil
  #
  # @return [Result::Base]
  #
  def get_registration_status

    r = SaasApi::OnBoarding::GetRegistrationStatus.new.perform({
                                                                 transaction_hash: @transaction_hash
                                                               })
    if @critical_chain_interaction_log.can_be_marked_timeout?
      # Timeout
      @critical_chain_interaction_log.status = GlobalConstant::CriticalChainInteractions.timeout_status
    elsif !r.success? || !r.data.present?
      # failed - service failure
      @critical_chain_interaction_log.status = GlobalConstant::CriticalChainInteractions.failed_status
    elsif r.data.present?

      # Save registration status
      @registration_status = r.data[:registration_status]
      save_response = save_registration_status

      if !save_response.success?
        # failed
        @critical_chain_interaction_log.status = GlobalConstant::CriticalChainInteractions.failed_status
      elsif registration_done?
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
        'j_s_grsj_2',
        'BT Registration failed.',
        'BT Registration failed.',
        GlobalConstant::ErrorAction.default,
        {}
      )
    end

  end

  # Enqueue job
  #
  # * Author: Kedar
  # * Date: 24/01/2018
  # * Reviewed By: Sunil
  #
  def enqueue_self
    BgJob.enqueue(
      ProposeBrandedToken::GetProposeStatusJob,
      {
        critical_log_id: @critical_log_id,
        parent_id: @parent_id
      },
      {
        wait: 10.seconds
      }
    )
  end

  # start the deployment of airdrop.
  #
  # * Author: Alpesh
  # * Date: 21/02/2018
  # * Reviewed By:
  #
  def deploy_airdrop_contract
    request_params = {
      client_id: @client_id,
      token_symbol: @client_token.symbol,
      token_name: @client_token.name
    }

    deploy_response = SaasApi::OnBoarding::DeployAirdropContract.new.perform(request_params)

    Rails.logger.debug(deploy_response)

    if deploy_response.success?
      status = GlobalConstant::CriticalChainInteractions.pending_status
      transaction_uuid = deploy_response.data[:transaction_uuid]
      transaction_hash = deploy_response.data[:transaction_hash]
    else
      status = GlobalConstant::CriticalChainInteractions.failed_status
    end

    Rails.logger.debug("params -------------------------------- p->#{@parent_id}, c->#{@client_id}")
    critical_log = CriticalChainInteractionLog.create!(
      {
        client_id: @client_id,
        parent_id: @parent_id,
        activity_type: GlobalConstant::CriticalChainInteractions.deploy_airdrop_activity_type,
        client_token_id: @client_token_id,
        chain_type: GlobalConstant::CriticalChainInteractions.utility_chain_type,
        transaction_uuid: transaction_uuid,
        transaction_hash: transaction_hash,
        request_params: request_params,
        response_data: deploy_response.to_hash,
        status: status
      }
    )

    BgJob.enqueue(
      Airdrop::GetAirdropDeployStatusJob,
      {
        critical_log_id: critical_log.id,
        parent_id: @parent_id
      },
      {
        wait: 10.seconds
      }
    ) if critical_log.is_pending?

  end

  # Save registration status
  #
  # * Author: Kedar
  # * Date: 24/01/2018
  # * Reviewed By: Sunil
  #
  # @return [Result::Base]
  #
  def save_registration_status

    set_propose_done if @registration_status[:is_proposal_done] == 1

    set_registered_on_uc if @registration_status[:is_registered_on_uc] == 1

    set_registered_on_vc if @registration_status[:is_registered_on_vc] == 1

    if @client_token.changed?
      @client_token.save!
      CacheManagement::ClientToken.new([@client_token.id]).clear
      CacheManagement::ClientTokenSecure.new([@client_token.id]).clear
    end

    # Update BT details in saas
    saas_response = send_proposed_branded_token_to_saas
    return saas_response

  end

  # Send proposed branded token details to SAAS
  #
  # * Author: Kedar
  # * Date: 24/01/2018
  # * Reviewed By: Sunil
  #
  # @return [Result::Base]
  #
  def send_proposed_branded_token_to_saas
    return success unless registration_done?

    r = SaasApi::OnBoarding::EditBt.new.perform(
      symbol: @client_token.symbol,
      symbol_icon: @client_token.symbol_icon,
      client_id: @client_id,
      token_erc20_address: @registration_status[:erc20_address],
      token_uuid: @registration_status[:uuid]
    )

    puts("registration EditBt rsp :: #{r.inspect}")

    return r
  end

  # set propose done
  #
  # * Author: Kedar
  # * Date: 24/01/2018
  # * Reviewed By: Sunil
  #
  def set_propose_done
    @client_token.send(
      "set_#{GlobalConstant::ClientToken.propose_done_setup_step}"
    )
  end

  # set registered on uc
  #
  # * Author: Kedar
  # * Date: 24/01/2018
  # * Reviewed By: Sunil
  #
  def set_registered_on_uc
    @client_token.send(
      "set_#{GlobalConstant::ClientToken.registered_on_uc_setup_step}"
    )
  end

  # set registered on vc
  #
  # * Author: Kedar
  # * Date: 24/01/2018
  # * Reviewed By: Sunil
  #
  def set_registered_on_vc
    @client_token.send(
      "set_#{GlobalConstant::ClientToken.registered_on_vc_setup_step}"
    )
    @client_token.token_erc20_address = @registration_status[:erc20_address]
  end

  # Is registration done
  #
  # * Author: Kedar
  # * Date: 24/01/2018
  # * Reviewed By: Sunil
  #
  # @return [Boolean]
  #
  def registration_done?
    propose_done? && registered_on_uc? && registered_on_vc?
  end

  # Is propose done
  #
  # * Author: Kedar
  # * Date: 24/01/2018
  # * Reviewed By: sunil
  #
  # @return [Boolean]
  #
  def propose_done?
    @client_token.send("#{GlobalConstant::ClientToken.propose_done_setup_step}?")
  end

  # Is registered on uc
  #
  # * Author: Kedar
  # * Date: 24/01/2018
  # * Reviewed By: Sunil
  #
  # @return [Boolean]
  #
  def registered_on_uc?
    @client_token.send("#{GlobalConstant::ClientToken.registered_on_uc_setup_step}?")
  end

  # Is registered on vc
  #
  # * Author: Kedar
  # * Date: 24/01/2018
  # * Reviewed By: Sunil
  #
  # @return [Boolean]
  #
  def registered_on_vc?
    @client_token.send("#{GlobalConstant::ClientToken.registered_on_vc_setup_step}?")
  end

end
