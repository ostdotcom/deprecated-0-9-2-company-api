class GetRegistrationStatusJob < ApplicationJob

  include Util::ResultHelper

  queue_as GlobalConstant::Sidekiq.queue_name :default_medium_priority_queue

  # Perform
  #
  # * Author: Kedar
  # * Date: 24/01/2018
  # * Reviewed By:
  #
  # @param [Integer] client_id (mandatory) - client id
  # @param [String] token_name (mandatory) - token name
  # @param [String] transation_hash (mandatory) - transaction hash of the proposal transaction
  #
  def perform(params)

    puts("registration status start :: #{params.inspect}")

    init_params(params)

    r = fetch_client_token
    return unless r.success?

    r = get_registration_status
    return unless r.success?

    puts("registration status:: #{@registration_status.inspect}")

    save_registration_status

    check_and_enqueue_job

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
    @max_run_time_delta = 30.minutes.to_i
    @transaction_hash = params[:transaction_hash]
    @client_id = params[:client_id]
    @client_token_id = params[:client_token_id]
    @critical_log_id = params[:critical_log_id]
    @started_job_at = params[:started_job_at]

    @registration_status = nil
    @client_token = nil
    @critical_chain_interaction_log_obj = nil

    @max_allowed_wait_time = 30.minutes
  end

  # Fetch client token
  #
  # * Author: Kedar
  # * Date: 24/01/2018
  # * Reviewed By:
  #
  # Sets @critical_chain_interaction_log_obj, @client_token
  #
  # @return [Result::Base]
  #
  def fetch_client_token
    @critical_chain_interaction_log_obj = CriticalChainInteractionLog.where(id: @critical_log_id)

    @started_job_at ||= @critical_chain_interaction_log_obj.created_at.to_i
    @client_token = ClientToken.where(id: @client_token_id).first

    return error_with_data(
      'grsj_1',
      'Token not found.',
      'Token not found.',
      GlobalConstant::ErrorAction.default,
      {}
    ) if @client_token.blank? || @client_token.status != GlobalConstant::ClientToken.active_status

    return error_with_data(
      'grsj_2',
      'Propose not yet initiated.',
      'Propose not yet initiated.',
      GlobalConstant::ErrorAction.default,
      {}
    ) unless propose_initiated?

    success
  end

  # Get Registration Status
  #
  # * Author: Kedar
  # * Date: 24/01/2018
  # * Reviewed By:
  #
  # @return [Result::Base]
  #
  def get_registration_status

    params = {
      transaction_hash: @transaction_hash
    }

    r = SaasApi::OnBoarding::GetRegistrationStatus.new.perform(params)

    @critical_chain_interaction_log_obj.debug_data = r
    @critical_chain_interaction_log_obj.status = GlobalConstant::CriticalChainInteractions.failed_status unless r.success?
    @critical_chain_interaction_log_obj.save!

    return r unless r.success?

    @registration_status = r.data[:registration_status]

    success

  end

  # Save registration status
  #
  # * Author: Kedar
  # * Date: 24/01/2018
  # * Reviewed By:
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
    end

  end

  # Enqueue job
  #
  # * Author: Kedar
  # * Date: 24/01/2018
  # * Reviewed By:
  #
  def check_and_enqueue_job

    if registration_done?

      @critical_chain_interaction_log_obj.status = GlobalConstant::CriticalChainInteractions.processed_status
      @critical_chain_interaction_log_obj.save!
      return

    elsif Time.now.to_i - @started_job_at > @max_run_time_delta

      @critical_chain_interaction_log_obj.status = GlobalConstant::CriticalChainInteractions.timeout_status
      @critical_chain_interaction_log_obj.save!
      return

    else

      BgJob.enqueue(
        GetRegistrationStatusJob,
        {
          transaction_hash: @transaction_hash,
          client_id: @client_id,
          client_token_id: @client_token_id,
          critical_log_id: @critical_log_id,
          started_job_at: @started_job_at
        },
        {
          wait: 30.seconds
        }
      )

    end

  end

  # set propose done
  #
  # * Author: Kedar
  # * Date: 24/01/2018
  # * Reviewed By:
  #
  def set_propose_done

    @client_token.send(
      "set_#{GlobalConstant::ClientToken.propose_done_setup_step}"
    )

    r = SaasApi::OnBoarding::EditBt.new.perform(
        symbol: @client_token.symbol,
        symbol_icon: @client_token.symbol_icon,
        client_id: @client_id,
        token_erc20_address: @registration_status[:erc20_address],
        token_uuid: @registration_status[:uuid]
    )

    puts("registration EditBt rsp :: #{r.inspect}")

    return r unless r.success?

    @client_token.token_erc20_address = @registration_status[:erc20_address]

  end

  # set registered on uc
  #
  # * Author: Kedar
  # * Date: 24/01/2018
  # * Reviewed By:
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
  # * Reviewed By:
  #
  def set_registered_on_vc
    @client_token.send(
      "set_#{GlobalConstant::ClientToken.registered_on_vc_setup_step}"
    )
  end

  # Is registration done
  #
  # * Author: Kedar
  # * Date: 24/01/2018
  # * Reviewed By:
  #
  # @return [Boolean]
  #
  def registration_done?
    propose_done? && registered_on_uc? && registered_on_vc?
  end

  # Is propose initiated
  #
  # * Author: Kedar
  # * Date: 24/01/2018
  # * Reviewed By:
  #
  # @return [Boolean]
  #
  def propose_initiated?
    @client_token.send("#{GlobalConstant::ClientToken.propose_initiated_setup_step}?")
  end

  # Is propose done
  #
  # * Author: Kedar
  # * Date: 24/01/2018
  # * Reviewed By:
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
  # * Reviewed By:
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
  # * Reviewed By:
  #
  # @return [Boolean]
  #
  def registered_on_vc?
    @client_token.send("#{GlobalConstant::ClientToken.registered_on_vc_setup_step}?")
  end

end
