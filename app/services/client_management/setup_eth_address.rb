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
      @info_salt_d = nil
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
      return r unless r.success?

      existing_db_record = ClientAddress.where(client_id: @client_id).last

      @hashed_eth_address = LocalCipher.get_sha_hashed_text(@eth_address)

      if existing_db_record.present?
        if existing_db_record.hashed_ethereum_address == @hashed_eth_address
          return success
        else
          return error_with_data(
              'cm_sea_1',
              'Client Already Has ETH address associated',
              'Client Already Has ETH address associated',
              GlobalConstant::ErrorAction.default,
              {}
          )
        end
      end

      r = decrypt_info_salt
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
    # @return [Result::Base]
    #
    def validate_and_sanitize

      r = validate
      return r unless r.success?

      # sanitize
      #TODO: Do we need to convert this to checksum ETH Address
      @eth_address = @eth_address.to_s.strip

      r = ClientManagement::ValidateEthAddress.new(client_id: @client_id, eth_address: @eth_address).perform
      return r unless r.success?

      @client = Client.where(id: @client_id).first

      return error_with_data(
          'cm_sea_2',
          'Invalid Client.',
          'Invalid Client.',
          GlobalConstant::ErrorAction.default,
          {}
      ) if @client.blank?

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

      r = Aws::Kms.new('info','user').decrypt(@client.info_salt)
      return r unless r.success?

      @info_salt_d = r.data[:plaintext]

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

      encryptor_obj = LocalCipher.new(@info_salt_d)
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
          status: GlobalConstant::ClientAddress.active_status
      )

      success

    end

  end

end
