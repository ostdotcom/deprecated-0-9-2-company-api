module Economy

  class GetTokenSetupDetails < ServicesBase

    # Initialize
    #
    # * Author: Puneet
    # * Date: 31/01/2018
    # * Reviewed By:
    #
    # @params [Integer] client_token_id (mandatory) - client token id
    # @params [Integer] user_id (mandatory) - user id
    #
    # @return [Economy::GetTokenSetupDetails]
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

      r = fetch_setup_details
      return r unless r.success?

      r = fetch_supporting_data
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

    # Fetch details about current setup state
    #
    # * Author: Puneet
    # * Date: 31/01/2018
    # * Reviewed By:
    #
    # Sets @api_response_data
    #
    def fetch_setup_details

      setup_steps_done = @client_token[:setup_steps]

      if setup_steps_done.include?(GlobalConstant::ClientToken.registered_on_vc_setup_step)

        # Step 3 was also performed, thus return relevant data

        r = FetchClientTokenSupplyDetails.new(client_token_id: @client_token[:id]).perform
        return r unless r.success?
        @api_response_data[:token_supply_details] = r.data

      elsif setup_steps_done.include?(GlobalConstant::ClientToken.configure_transactions_setup_step)

        # step 2 was performed, we would return data needed to perform step 3

      elsif setup_steps_done.include?(GlobalConstant::ClientToken.set_conversion_rate_setup_step)

        # step 1 was performed, we would return data needed to perform step 2

        r = Economy::TransactionKind::List.new(
            client_id: @client_token[:client_id],
            client_token_id: @client_token[:id],
            user_id: @user_id
        ).perform
        return r unless r.success?

        @api_response_data[:transaction_kinds] = r.data['transaction_kinds']

      else # no step was performed, return data to perform step 1

        # no extra data to return

      end

      success

    end

    # fetch supporting data for pi responce
    #
    # * Author: Puneet
    # * Date: 29/01/2018
    # * Reviewed By:
    #
    # Sets @api_response_data
    #
    # @return [Result::Base]
    #
    def fetch_supporting_data

      r = Util::FetchEconomyCommonEntities.new(user_id: @user_id, client_token: @client_token).perform
      return r unless r.success?

      @api_response_data.merge!(r.data)

      success

    end

  end

end
