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
    # @return [ClientManagement::ValidateEthAddress]
    #
    def initialize(params)

      super

      @client_id = @params[:client_id]
      @eth_address = @params[:eth_address]

      @client = nil
      @hashed_eth_address = nil

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

      @hashed_eth_address = LocalCipher.get_sha_hashed_text(@eth_address)

      validate_eth_address_from_db

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

      @client = CacheManagement::Client.new([@client_id]).fetch[@client_id]

      return error_with_data(
          'cm_vea_2',
          'Invalid Client.',
          'Invalid Client.',
          GlobalConstant::ErrorAction.default,
          {}
      ) if @client.blank? || @client[:status] != GlobalConstant::Client.active_status

      @client_id = @client_id.to_i

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
    def validate_eth_address_from_db

      # check if this client already has an eth address associated
      client_address = ClientAddress.where(client_id: @client_id).last
      return error_with_data(
          'cm_vea_4',
          'Invalid ETH Address.', # do we have to reveal in this message that eth address was associated with someone else
          'Invalid ETH Address.',
          GlobalConstant::ErrorAction.default,
          {}
      ) if client_address.present? && client_address.hashed_ethereum_address != @hashed_eth_address

      # check if this eth address is associted by any other address
      client_address = ClientAddress.where(hashed_ethereum_address: @hashed_eth_address).last
      return error_with_data(
          'cm_vea_5',
          'Invalid ETH Address.', # do we have to reveal in this message that eth address was associated with someone else
          'Invalid ETH Address.',
          GlobalConstant::ErrorAction.default,
          {}
      ) if client_address.present? && client_address.client_id != @client_id
      
      success

    end

  end

end
