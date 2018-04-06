module ClientManagement

  class GetClientApiCredentials < ServicesBase

    # Initialize
    #
    # * Author: Pankaj
    # * Date: 29/01/2018
    # * Reviewed By:
    #
    # @param [Integer] client_id (mandatory) - Client Id for which Api credentials has to be fetched
    #
    # @return [ClientManagement::GetClientApiCredentials]
    #
    def initialize(params)

      super

      @client_id = params[:client_id]
      @client = nil
      @client_api_credentials = nil
      @api_secret_d = nil

    end

    # Perform
    #
    # * Author: Pankaj
    # * Date: 29/01/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def perform

      r = validate_client
      return r unless r.success?

      r = fetch_api_credentials
      return r unless r.success?

      r = decrypt_api_secret
      return r unless r.success?

      success_with_data(
        api_credentials: {
          api_key: @client_api_credentials.api_key,
          api_secret: @api_secret_d
        }
      )

    end

    private

    # Validate Input client
    #
    # * Author: Pankaj
    # * Date: 29/01/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    # Sets @client
    #
    def validate_client

      r = validate
      return r unless r.success?

      @client = CacheManagement::Client.new([@client_id]).fetch[@client_id]

      return error_with_data('cm_gcac_1',
                             "Invalid client.",
                             'Something Went Wrong.',
                             GlobalConstant::ErrorAction.mandatory_params_missing,
                             {}) unless @client.present?

      success

    end

    # Decrypt client Info salt
    #
    # * Author: Pankaj
    # * Date: 29/01/2018
    # * Reviewed By:
    #
    # Sets @api_secret_d
    #
    # @return [Result::Base]
    #
    def decrypt_api_secret

      r = Aws::Kms.new('api_key','user').decrypt(@client_api_credentials.api_salt)
      return r unless r.success?

      info_salt_d = r.data[:plaintext]

      r = LocalCipher.new(info_salt_d).decrypt(@client_api_credentials.api_secret)
      return r unless r.success?

      @api_secret_d = r.data[:plaintext]

      success

    end

    # Fetch api credentials for client & decrypt client secret key
    #
    # * Author: Pankaj
    # * Date: 29/01/2018
    # * Reviewed By:
    #
    # Set @client_api_credentials
    #
    # @return [Result::Base]
    #
    def fetch_api_credentials

      @client_api_credentials = ClientApiCredential.where(client_id: @client_id).last

      return error_with_data('cm_gcac_2',
                             "Invalid client.",
                             'Something Went Wrong.',
                             GlobalConstant::ErrorAction.mandatory_params_missing,
                             {}) unless @client_api_credentials.present?

      success

    end

  end

end
