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
      @info_salt_d = nil
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

      r = decrypt_info_salt
      return r unless r.success?

      r = fetch_api_credentials
      return r

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
    def validate_client
      r = validate
      return r unless r.success?

      @client = Client.where(id: @client_id).first
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
    # Sets @info_salt_d
    #
    # @return [Result::Base]
    #
    def decrypt_info_salt
      r = Aws::Kms.new('info','user').decrypt(@client.info_salt)
      return r unless r.success?

      @info_salt_d = r.data[:plaintext]

      success
    end

    # Fetch api credentials for client & decrypt client secret key
    #
    # * Author: Pankaj
    # * Date: 29/01/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def fetch_api_credentials
      client_api = ClientApiCredential.where(client_id: @client_id).first
      return error_with_data('cm_gcac_2',
                             "Invalid client.",
                             'Something Went Wrong.',
                             GlobalConstant::ErrorAction.mandatory_params_missing,
                             {}) unless client_api.present?

      secret_key = decrypt_secret_key(client_api.api_secret)
      return error_with_data('cm_gcac_3',
                             "Invalid client.",
                             'Something Went Wrong.',
                             GlobalConstant::ErrorAction.mandatory_params_missing,
                             {}) unless secret_key.present?

      success_with_data(api_key: client_api.api_key, api_secret: secret_key)

    end

    # Decrypt api secret key with client info salt
    #
    # * Author: Pankaj
    # * Date: 29/01/2018
    # * Reviewed By:
    #
    # @return [String] secret Key
    #
    def decrypt_secret_key(api_secret)
      decryptor_obj = LocalCipher.new(@info_salt_d)
      r = decryptor_obj.decrypt(api_secret)

      return (r.success? ? r.data[:plaintext] : nil)
    end

  end

end
