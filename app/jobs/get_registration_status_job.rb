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
  # @param [Hash] stake_params (mandatory) - stake params
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

    enqueue_job

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
    @transaction_hash = params[:transaction_hash]
    @client_id = params[:client_id]
    @token_name = params[:token_name]
    @stake_params = params[:stake_params]

    @registration_status = nil
    @client_token = nil
  end

  # Fetch client token
  #
  # * Author: Kedar
  # * Date: 24/01/2018
  # * Reviewed By:
  #
  # @return [Result::Base]
  #
  def fetch_client_token
    @client_token = ClientToken.where(
      name: @token_name,
      client_id: @client_id,
      status: GlobalConstant::ClientToken.active_status
    ).first

    return error_with_data(
      'grsj_1',
      'Token not found.',
      'Token not found.',
      GlobalConstant::ErrorAction.default,
      {}
    ) unless @client_token.present?

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
  def enqueue_job

    if registration_done?

      @stake_params[:uuid] = @registration_status[:uuid]

      BgJob.enqueue(
        Stake::ApproveJob,
        {
          stake_params: @stake_params
        }
      )

    else

      BgJob.enqueue(
        GetRegistrationStatusJob,
        {
          transaction_hash: @transaction_hash,
          client_id: @client_id,
          token_name: @token_name,
          stake_params: @stake_params
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
