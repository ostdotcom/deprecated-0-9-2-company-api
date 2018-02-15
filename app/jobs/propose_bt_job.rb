class ProposeBtJob < ApplicationJob

  include Util::ResultHelper

  queue_as GlobalConstant::Sidekiq.queue_name :default_medium_priority_queue

  # Perform
  #
  # * Author: Kedar
  # * Date: 24/01/2018
  # * Reviewed By:
  #
  # @param [Integer] client_id (mandatory) - client id
  # @param [String] token_symbol (mandatory) - token symbol
  # @param [String] token_name (mandatory) - token name
  # @param [String] token_conversion_rate (mandatory) - token conversion rate
  # @param [Hash] stake_params (mandatory) - stake params - to_stake_amount and beneficiary should be present
  #
  def perform(params)

    init_params(params)

    r = fetch_client_details
    return unless r.success?

    r = propose
    return unless r.success?

    Rails.logger.info("propose initiated with transaction hash:: #{@transaction_hash}")

    # enqueue the get registration status job
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
    @client_id = params[:client_id]
    @client_token_id = params[:client_token_id]
    @token_symbol = params[:token_symbol]
    @token_name = params[:token_name]
    @token_conversion_rate = params[:token_conversion_rate].to_f
    @stake_params = params[:stake_params]

    @transaction_hash = nil
    @client_token = nil

  end

  # Fetch client token
  #
  # * Author: Kedar
  # * Date: 24/01/2018
  # * Reviewed By:
  #
  # Sets @client, @client_token
  #
  # @return [Result::Base]
  #
  def fetch_client_details

    @client = CacheManagement::Client.new([@client_id]).fetch[@client_id]
    return error_with_data(
        'pbj_',
        'Invalid Client.',
        'Invalid Client.',
        GlobalConstant::ErrorAction.default,
        {}
    ) if @client.blank? || @client[:status] != GlobalConstant::Client.active_status

    @client_token = ClientToken.where(id: @client_token_id).first

    return error_with_data(
      'pbj_2',
      'Token not found.',
      'Token not found.',
      GlobalConstant::ErrorAction.default,
      {}
    ) if @client_token.blank? || @client_token.status != GlobalConstant::ClientToken.active_status

    success

  end

  # Propose
  #
  # * Author: Kedar
  # * Date: 24/01/2018
  # * Reviewed By:
  #
  # @return [Result::Base]
  #
  def propose

    params = {
      token_symbol: @token_symbol,
      token_name: @token_name,
      token_conversion_rate: @token_conversion_rate
    }

    r = SaasApi::OnBoarding::ProposeBt.new.perform(params)
    return r unless r.success?

    @transaction_hash =  r.data[:transaction_hash]

    success

  end

  # Enqueue job
  #
  # * Author: Kedar
  # * Date: 24/01/2018
  # * Reviewed By:
  #
  def enqueue_job
    BgJob.enqueue(
      GetRegistrationStatusJob,
      {
        transaction_hash: @transaction_hash,
        client_id: @client_id,
        token_name: @token_name,
        stake_params: @stake_params
      },
      {
        wait: 100.seconds
      }
    )
  end

end
