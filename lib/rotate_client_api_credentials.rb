class RotateClientApiCredentials

  include Util::ResultHelper

  # Initialize
  #
  # * Author: Puneet
  # * Date: 02/02/2018
  # * Reviewed By:
  #
  # @param [Integer] client_id (mandatory) - Client Id for which Api credentials has to be rotated
  #
  def initialize(params)

    @client_id = params[:client_id]

    @api_credential = nil

  end

  # Fetch balances from Platform
  #
  # * Author: Puneet
  # * Date: 01/02/2018
  # * Reviewed By:
  #
  # @return [Result::Base]
  #
  def perform

    r = validate
    return r unless r.success?

    r = create_client_api_credentials
    return r unless r.success?

    r = inactivate_old_api_credentials
    return r unless r.success?

    # how to flush shared cache from all memcache instances ?
    CacheManagement::ClientApiCredentials.new([@client_id]).clear

    success

  end

  private

  # validate
  #
  # * Author: Puneet
  # * Date: 01/02/2018
  # * Reviewed By:
  #
  # @return [Result::Base]
  #
  def validate

    return error_with_data(
        'r_c_a_c_1',
        'invalid_api_params',
        GlobalConstant::ErrorAction.default
    ) if @client_id.blank?

    @client = CacheManagement::Client.new([@client_id]).fetch[@client_id]

    return error_with_data(
        'r_c_a_c_2',
         "Invalid client.",
         'Something Went Wrong.',
         GlobalConstant::ErrorAction.mandatory_params_missing,
         {}
    ) if @client.blank? || @client[:status] != GlobalConstant::Client.active_status

    success

  end

  # Generate Client Api Credentials
  #
  #
  # * Author: Puneet
  # * Date: 14/02/2018
  # * Reviewed By:
  #
  # Sets @api_credential
  #
  # @return [Result::Base]
  #
  def create_client_api_credentials

    r = Aws::Kms.new('api_key', 'user').generate_data_key
    return unless r.success?

    api_salt = r.data

    @api_credential = ClientApiCredential.new(
        client_id: @client_id,
        api_key: ClientApiCredential.generate_random_app_id,
        api_secret: ClientApiCredential.generate_encrypted_secret_key(api_salt[:plaintext]),
        api_salt: api_salt[:ciphertext_blob],
        expiry_timestamp: (Time.now+10.year).to_i
    )

    @api_credential.save!

    success

  end

  # Generate Client Api Credentials
  #
  #
  # * Author: Puneet
  # * Date: 14/02/2018
  # * Reviewed By:
  #
  # @return [Result::Base]
  #
  def inactivate_old_api_credentials

    ClientApiCredential.where(client_id: @client_id).where('id != ?', @api_credential.id).
        update_all(expiry_timestamp: current_timestamp, updated_at: current_time)

    success

  end

end