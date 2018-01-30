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

      r = decrypt_info_salt
      return r unless r.success?

      r = encrypt_eth_address
      return r unless r.success?

      update_eth_address_in_db

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

      return error_with_data(
          'cm_sea_1',
          'Invalid Eth Address.',
          'Invalid Eth Address.',
          GlobalConstant::ErrorAction.default,
          {}
      ) unless Util::CommonValidator.is_ethereum_address?(@eth_address)

      @client = Client.where(id: @client_id).first

      return error_with_data(
          'cm_sea_2',
          'Invalid Client.',
          'Invalid Client.',
          GlobalConstant::ErrorAction.default,
          {}
      ) if @client.blank? || @client.status != GlobalConstant::Client.active_status

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
    # Sets @hashed_eth_address & @encrypted_eth_address
    #
    # @return [Result::Base]
    #
    def encrypt_eth_address

      @hashed_eth_address = Digest::SHA256.hexdigest(@eth_address.downcase)

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
    def update_eth_address_in_db

      ClientAddress.where(client_id: @client_id).update_all(status: GlobalConstant::ClientAddress.inactive_status)

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
