module Util

  # This class could be used to fetch entities which needs to be sent to FE
  # in prety much all requests for economy related pages

  class FetchEconomyCommonEntities

    include Util::ResultHelper

    # Initialize
    #
    # * Author: Puneet
    # * Date: 02/02/2018
    # * Reviewed By:
    #
    def initialize(params)

      @user_id = params[:user_id]
      @client_token_id = params[:client_token_id]

      @client_token = params[:client_token]
      @user = params[:user]
      @client_balances = params[:client_balances]

    end

    # Fetch remaining entites and returns formatted response
    #
    # * Author: Puneet
    # * Date: 02/02/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def perform

      r = fetch_user
      return r unless r.success?

      r = fetch_client_token
      return r unless r.success?

      r = fetch_client_balances
      return r unless r.success?

      return formatted_response

    end

    private

    #
    # * Author: Puneet
    # * Date: 02/02/2018
    # * Reviewed By:
    #
    # Sets @user
    #
    # @return [Result::Base]
    #
    def fetch_user

      return success if @user.present?

      return error_with_data(
          'u_fece_1',
          "Invalid User Id.",
          "Invalid User Id.",
          GlobalConstant::ErrorAction.mandatory_params_missing,
          {}
      ) if @user_id.blank?

      @user = CacheManagement::User.new([@user_id]).fetch[@user_id]

      success

    end

    #
    # * Author: Puneet
    # * Date: 02/02/2018
    # * Reviewed By:
    #
    # Sets @client_token
    #
    # @return [Result::Base]
    #
    def fetch_client_token

      if @client_token.present?
        @client_token_id = @client_token[:id]
        return success
      end

      return error_with_data(
          'u_fece_2',
          "Invalid Client Token Id.",
          "Invalid Client Token Id.",
          GlobalConstant::ErrorAction.mandatory_params_missing,
          {}
      ) if @client_token_id.blank?

      @client_token = CacheManagement::ClientToken.new([@client_token_id]).fetch[@client_token_id]

      @client_token_id = @client_token[:id]

      success

    end

    #
    # * Author: Puneet
    # * Date: 02/02/2018
    # * Reviewed By:
    #
    # Sets @client_token_balance
    #
    # @return [Result::Base]
    #
    def fetch_client_balances

      return success if @client_balances.present?

      @client_token_s = CacheManagement::ClientTokenSecure.new([@client_token_id]).fetch[@client_token_id]

      balance_types = [
        GlobalConstant::BalanceTypes.ost_balance_type,
        GlobalConstant::BalanceTypes.ost_prime_balance_type,
        GlobalConstant::BalanceTypes.branded_token_balance_type
      ]

      r = FetchClientBalances.new(
        client_id: @client_token[:client_id],
        address: @client_token_s[:reserve_address],
        erc20_address: @client_token_s[:erc20_address]
      ).perform(balance_types)

      if r.success?
        @client_balances = r.data
      end

      success

    end

    #
    # * Author: Puneet
    # * Date: 02/02/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def formatted_response

      success_with_data(
        client_token: @client_token,
        user: @user,
        client_balances: @client_balances
      )

    end

  end

end