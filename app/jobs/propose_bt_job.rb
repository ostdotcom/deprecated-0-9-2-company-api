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
  #
  def perform(params)

    init_params(params)

    r = fetch_client_token
    return unless r.success?

    r = propose
    return unless r.success?

    update_client_token

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
    @token_symbol = params[:token_symbol]
    @token_name = params[:token_name]
    @token_conversion_rate = params[:token_conversion_rate].to_f

    @transaction_hash = nil
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
      'pbj_1',
      'Token not found.',
      'Token not found.',
      GlobalConstant::ErrorAction.default,
      {}
    ) unless @client_token.present?

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
      # TODO - talk with Sunil for who will pass the following 2 params - rails or node.
      sender_address: '0x8312731f3c4446b6aae61caebdf9c9249409f140',
      sender_passphrase: 'testtest',
      token_symbol: @token_symbol,
      token_name: @token_name,
      token_conversion_rate: @token_conversion_rate
    }

    r = ManagementApi::OnBoarding::ProposeBt.new.perform(params)
    return r unless r.success?

    @transaction_hash =  r.data[:transaction_hash]

    success
  end

  # Update client token
  #
  # * Author: Kedar
  # * Date: 24/01/2018
  # * Reviewed By:
  #
  # @return [Result::Base]
  #
  def update_client_token
    @client_token.send("set_#{GlobalConstant::ClientToken.propose_initiated_setup_step}")
    @client_token.save!
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
        token_name: @token_name
      },
      {
        wait: 100.seconds
      }
    )
  end

end
