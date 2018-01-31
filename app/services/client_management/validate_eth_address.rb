module ClientManagement

  class ValidateEthAddress < ServicesBase

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
      @hashed_eth_address_from_db = nil

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

      r = fetch_eth_address_from_db
      return r unless r.success?

      hashed_eth_address = LocalCipher.get_sha_hashed_text(@eth_address)

      hashed_eth_address == @hashed_eth_address_from_db ? success : error_with_data(
          'cm_vea_3',
          'Invalid ETH Address.',
          'Invalid ETH Address.',
          GlobalConstant::ErrorAction.default,
          {}
      )

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
          'cm_vea_1',
          'Invalid Eth Address.',
          'Invalid Eth Address.',
          GlobalConstant::ErrorAction.default,
          {}
      ) unless Util::CommonValidator.is_ethereum_address?(@eth_address)

      @client = Client.where(id: @client_id).first

      return error_with_data(
          'cm_vea_2',
          'Invalid Client.',
          'Invalid Client.',
          GlobalConstant::ErrorAction.default,
          {}
      ) if @client.blank? || @client.status != GlobalConstant::Client.active_status

      success

    end

    # Validate Eth Address
    #
    # * Author: Puneet
    # * Date: 29/01/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def fetch_eth_address_from_db

      client_address = ClientAddress.where(client_id: @client_id).last
      return error_with_data(
          'cm_vea_4',
          'Invalid Client.',
          'Invalid Client.',
          GlobalConstant::ErrorAction.default,
          {}
      ) if client_address.blank?

      @hashed_eth_address_from_db = client_address.hashed_ethereum_address
      
      success

    end

  end

end
