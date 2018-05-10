module Economy

  class GetTokenSupplyDetails < ServicesBase

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
      return validation_error(
          'e_gtss_1',
          'invalid_api_params',
          ['invalid_client_token_id'],
          GlobalConstant::ErrorAction.default
      ) if @client_token.blank?

      return error_with_go_to(
          'e_gtss_2',
          'token_setup_not_complete',
          GlobalConstant::GoTo.economy_planner_step_one
      ) if @client_token[:setup_steps].exclude?(GlobalConstant::ClientToken.setup_complete_step)

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

      r = Util::FetchEconomyCommonEntities.new(
        user_id: @user_id,
        client_token_id: @client_token_id,
        client_token: @client_token
      ).perform
      return r unless r.success?

      @api_response_data.merge!(r.data)

      success

    end
    
  end
  
end
