module Economy

  class GetCriticalChainInteractionStatus < ServicesBase

    # Initialize
    #
    # * Author: Puneet
    # * Date: 31/01/2018
    # * Reviewed By:
    #
    # @params [Integer] critical_chain_interaction_log_id (mandatory) - critical_chain_interaction_log_id
    # @params [Integer] user_id (mandatory) - user id
    # @params [Integer] client_id (mandatory) - client id
    # @params [Integer] client_token_id (mandatory) - client token id
    #
    # @return [Economy::GetCriticalChainInteractionStatus]
    #
    def initialize(params)

      super

      @user_id = @params[:user_id]
      @client_token_id = @params[:client_token_id]
      @client_id = @params[:client_id]
      @critical_chain_interaction_log_id = @params[:critical_chain_interaction_log_id]

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

      r = validate_and_sanitize
      return r unless r.success?

      r = fetch_client_token
      return r unless r.success?

      r = fetch_critical_chain_interaction_status
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
    # @return [Result::Base]
    #
    def validate_and_sanitize

      r = validate
      return r unless r.success?

      return error_with_data(
          'e_gtss_1',
          'Invalid id.',
          'Invalid id.',
          GlobalConstant::ErrorAction.default,
          {}
      ) unless Util::CommonValidator.is_numeric?(@critical_chain_interaction_log_id)

      @critical_chain_interaction_log_id = @critical_chain_interaction_log_id.to_i

      success

    end

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
          'e_gtss_2',
          'Token not found.',
          'Token not found.',
          GlobalConstant::ErrorAction.default,
          {}
      ) if @client_token.blank?

      success

    end

    #
    # * Author: Puneet
    # * Date: 31/01/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def fetch_critical_chain_interaction_status

      @api_response_data[:critical_chain_interaction_status] = CacheManagement::CriticalChainInteractionStatus.new([@critical_chain_interaction_log_id]).fetch[@critical_chain_interaction_log_id]

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

