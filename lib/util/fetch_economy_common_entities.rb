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
      @client_token_balance = params[:client_token_balance]
      @client_ost_balance = params[:client_ost_balance]

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

      r = fetch_client_token_balance
      return r unless r.success?

      r = fetch_client_ost_balance
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

      return success if @client_token.present?

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
    def fetch_client_token_balance

      return success if @client_token_balance.present?

      r = FetchClientTokenBalance.new(client_token: @client_token).perform
      return r unless r.success?
      @client_token_balance = r.data

      success

    end

    #
    # * Author: Puneet
    # * Date: 02/02/2018
    # * Reviewed By:
    #
    # Sets @client_ost_balance
    #
    # @return [Result::Base]
    #
    def fetch_client_ost_balance

      return success if @client_ost_balance.present?

      r = FetchClientOstBalance.new(client_id: @client_token[:client_id]).perform
      return r unless r.success?

      @client_ost_balance = r.data

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
        client_token_balance: @client_token_balance,
        client_ost_balance: @client_ost_balance,
        ost_fiat_conversion_factors: FetchOstFiatConversionFactors.perform
      )

    end

  end

end