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

    r = decrypt_info_salt
    return r unless r.success?

    r = create_reserve_address
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
    @stake_params = params[:stake_params]

    @transaction_hash = nil
    @client_token = nil
    @reserve_address = nil
    @encrypted_passphrase = nil
    @info_salt_d = nil

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

    @client = Client.where(id: @client_id).first
    return error_with_data(
        'pbj_',
        'Invalid Client.',
        'Invalid Client.',
        GlobalConstant::ErrorAction.default,
        {}
    ) if @client.blank? || @client.status != GlobalConstant::Client.active_status

    @client_token = ClientToken.where(
      name: @token_name,
      client_id: @client_id,
      status: GlobalConstant::ClientToken.active_status
    ).first

    return error_with_data(
      'pbj_2',
      'Token not found.',
      'Token not found.',
      GlobalConstant::ErrorAction.default,
      {}
    ) unless @client_token.present?

    success

  end

  # Decrypt client Info salt
  #
  # * Author: Puneet
  # * Date: 29/01/2018
  # * Reviewed By:
  #
  # Sets @info_salt_d
  #
  # @return [Result::Base]
  #
  def decrypt_info_salt

    # Decrypt info salt of client
    r = Aws::Kms.new('info','user').decrypt(@client.info_salt)
    return r unless r.success?

    @info_salt_d = r.data[:plaintext]

    success

  end

  # Create an address on UC which would act as Reserve address for this BT
  #
  # * Author: Puneet
  # * Date: 29/01/2018
  # * Reviewed By:
  #
  # @return [Result::Base]
  #
  def create_reserve_address

    # Create address with this passphrase on Chain
    r = ClientManagement::GetClientApiCredentials.new(client_id: @client_id).perform
    return unless r.success?

    # Create OST Sdk Obj
    credentials = OSTSdk::Util::APICredentials.new(r.data[:api_key], r.data[:api_secret])
    sdk_obj = OSTSdk::Saas::Addresses.new(GlobalConstant::Base.sub_env, credentials)

    # Generate random password
    passphrase = SecureRandom.hex(12)

    r = sdk_obj.create(passphrase: passphrase)
    return unless r.success?
    @reserve_address = r.data['ethereum_address']

    # Using Info Salt, encrypt passowrd using local cypher
    encryptor_obj = LocalCipher.new(@info_salt_d)
    r = encryptor_obj.encrypt(passphrase)
    return r unless r.success?

    @encrypted_passphrase = r.data[:ciphertext_blob]

    @client_token.reserve_address = @reserve_address
    @client_token.reserve_passphrase = @encrypted_passphrase
    @client_token.save

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
        token_name: @token_name,
        stake_params: @stake_params
      },
      {
        wait: 100.seconds
      }
    )
  end

end
