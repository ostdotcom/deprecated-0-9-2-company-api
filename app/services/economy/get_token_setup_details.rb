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
      @api_response = {}

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

      @api_response = {
          client_token: @client_token,
          user: CacheManagement::User.new([@user_id]).fetch[@user_id]
      }

      success_with_data(@api_response)

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
    # Sets @api_response
    #
    def fetch_setup_details

      setup_steps_done = @client_token[:setup_steps]

      if setup_steps_done.include?(GlobalConstant::ClientToken.registered_on_vc_setup_step)

        # Step 3 was also performed, thus return relevant data

        @api_response[:token_supply_details] = FetchClientTokenSupplyDetails.new(client_token_id: @client_token[:id]).perform

        @api_response[:client_token_balance] = FetchClientTokenBalance.new(client_token: @client_token).perform

      elsif setup_steps_done.include?(GlobalConstant::ClientToken.configure_transactions_setup_step)

        # step 2 was performed, we would return data needed to perform step 3

        @api_response[:client_ost_balance] = FetchClientOstBalance.new(client_id: @client_token[:client_id]).perform

      elsif setup_steps_done.include?(GlobalConstant::ClientToken.set_conversion_rate_setup_step)

        # step 1 was performed, we would return data needed to perform step 2

        r = Economy::TransactionKind::List.new(client_id: @client_token[:client_id]).perform
        return r unless r.success?

        @api_response[:transaction_kinds] = r.data['transaction_kinds']

      else # no step was performed, return data to perform step 1

        # no extra data to return

      end

      success

    end

  end

end
