module ClientManagement

  class SetupEthAddress < ServicesBase

    # Initialize
    #
    # * Author: Puneet
    # * Date: 29/01/2018
    # * Reviewed By:
    #
    # @param [Integer] client_id (mandatory) - Client Id for which Eth address has to be set up
    # @param [String] eth_address (mandatory) - eth address
    #
    # @return [ClientManagement::SetupEthAddress]
    #
    def initialize(params)

      super

      @client_id = @params[:client_id]
      @eth_address = @params[:eth_address]

      @client = nil
      @client_address = nil
      @address_salt = nil
      @hashed_eth_address = nil
      @encrypted_eth_address = nil

    end

    # Perform
    #
    # * Author: Puneet
    # * Date: 29/01/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def perform

      r = validate_and_sanitize
      return r if (r.failed? || @client_address.present?)

      r = generate_address_salt
      return r unless r.success?

      r = encrypt_eth_address
      return r unless r.success?

      create_eth_address_in_db

    end

    private

    # Validate and sanitize
    #
    # * Author: Puneet
    # * Date: 29/01/2018
    # * Reviewed By:
    #
    # Sets @hashed_eth_address, @client_address
    #
    # @return [Result::Base]
    #
    def validate_and_sanitize

      r = validate
      return r unless r.success?

      @client = CacheManagement::Client.new([@client_id]).fetch[@client_id]

      return validation_error(
          'cm_sea_1',
          'invalid_api_params',
          ['invalid_client_id'],
          GlobalConstant::ErrorAction.default
      ) if @client.blank?

      @client_address = ClientAddress.where(client_id: @client_id).last

      @hashed_eth_address = LocalCipher.get_sha_hashed_text(@eth_address)

      if @client_address.present?
        if @client_address.hashed_ethereum_address == @hashed_eth_address
          return success
        else
          return error_with_data(
              'cm_sea_2',
              'already_associated',
              GlobalConstant::ErrorAction.default
          )
        end
      end

      # sanitize
      #TODO: Do we need to convert this to checksum ETH Address
      @eth_address = @eth_address.to_s.strip

      r = ClientManagement::ValidateEthAddress.new(client_id: @client_id, eth_address: @eth_address).perform
      return r unless r.success?

      success

    end

    # Generate Address Salt for client.
    #
    # * Author: Pankaj
    # * Date: 16/02/2018
    # * Reviewed By:
    #
    # Sets @address_salt
    #
    # @return [Result::Base]
    #
    def generate_address_salt

      r = Aws::Kms.new('api_key','user').generate_data_key
      return r unless r.success?

      @address_salt = r.data

      success

    end

    # Encrypt Eth Address
    #
    # * Author: Puneet
    # * Date: 29/01/2018
    # * Reviewed By:
    #
    # Sets @encrypted_eth_address
    #
    # @return [Result::Base]
    #
    def encrypt_eth_address

      encryptor_obj = LocalCipher.new(@address_salt[:plaintext])
      r = encryptor_obj.encrypt(@eth_address)
      return r unless r.success?

      @encrypted_eth_address = r.data[:ciphertext_blob]

      success

    end

    # Update Eth Address in DB
    #
    # * Author: Puneet
    # * Date: 29/01/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def create_eth_address_in_db

      ClientAddress.create(
          client_id: @client_id,
          ethereum_address: @encrypted_eth_address,
          hashed_ethereum_address: @hashed_eth_address,
          address_salt: @address_salt[:ciphertext_blob],
          status: GlobalConstant::ClientAddress.active_status
      )

      CacheManagement::ClientAddress.new([@client_id]).clear

      success

    end

  end

end
