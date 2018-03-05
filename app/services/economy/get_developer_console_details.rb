module Economy

  class GetDeveloperConsoleDetails < ServicesBase

    # Initialize
    #
    # * Author: Puneet
    # * Date: 31/01/2018
    # * Reviewed By:
    #
    # @params [Integer] client_token_id (mandatory) - client token id
    # @params [Integer] user_id (mandatory) - user id
    #
    # @return [Economy::GetTokenSupplyDetails]
    #
    def initialize(params)

      super

      @user_id = @params[:user_id]
      @client_token_id = @params[:client_token_id]

      @client_token = nil
      @client_token_secure = nil
      @api_response_data = {}

    end

    # Perform
    #
    # * Author: Puneet
    # * Date: 31/01/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def perform

      r = validate
      return r unless r.success?

      r = fetch_client_token
      return r unless r.success?

      r = fetch_client_token_secure
      return r unless r.success?

      r = fetch_common_entities
      return r unless r.success?

      success_with_data(@api_response_data)

    end

    private

    #
    # * Author: Puneet
    # * Date: 31/01/2018
    # * Reviewed By:
    #
    # Sets @client_token
    #
    def fetch_client_token

      @client_token = CacheManagement::ClientToken.new([@client_token_id]).fetch[@client_token_id]
      return error_with_data(
          'e_gtss_1',
          'Token not found.',
          'Token not found.',
          GlobalConstant::ErrorAction.default,
          {}
      ) if @client_token.blank?

      success

    end

    #
    # * Author: Aman
    # * Date: 05/03/2018
    # * Reviewed By:
    #
    # Sets @client_token_secure
    #
    def fetch_client_token_secure
      @client_token_secure = CacheManagement::ClientTokenSecure.new([@client_token_id]).fetch[@client_token_id]

      return error_with_data(
          'e_gtss_fcts_1',
          'Token not found.',
          'Token not found.',
          GlobalConstant::ErrorAction.default,
          {}
      ) if @client_token_secure.blank?

      @api_response_data[:contract_addresses] = {
          erc20_contract_address: @client_token_secure[:token_erc20_address],
          airdrop_contract_address: @client_token_secure[:airdrop_contract_address]
      }

      success
    end

    #
    # * Author: Puneet
    # * Date: 31/01/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def fetch_common_entities

      r = Util::FetchEconomyCommonEntities.new(user_id: @user_id, client_token_id: @client_token_id).perform
      return r unless r.success?

      @api_response_data.merge!(r.data)

      success

    end

  end

end
