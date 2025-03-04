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
      @client_balances_data = params[:client_balances]
      @client_token_pending_transactions = params[:client_token_pending_transactions]

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

      r = fetch_token_supply_details
      return r unless r.success?

      r = fetch_pending_transactions
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
          'something_went_wrong',
          GlobalConstant::ErrorAction.default
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
          'something_went_wrong',
          GlobalConstant::ErrorAction.mandatory_params_missing
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

      return success if @client_balances_data.present?

      client_address_data = CacheManagement::ClientAddress.new([@client_token[:client_id]]).fetch[@client_token[:client_id]]

      return error_with_go_to(
          'fece_1',
          'token_setup_not_complete',
          GlobalConstant::GoTo.economy_planner_step_one
      ) if client_address_data.blank? || client_address_data[:ethereum_address_d].blank?

      client_token_s = CacheManagement::ClientTokenSecure.new([@client_token_id]).fetch[@client_token_id]

      return error_with_go_to(
          'fece_2',
          'token_setup_not_complete',
          GlobalConstant::GoTo.economy_planner_step_three
      ) if client_token_s.blank? || client_token_s[:reserve_uuid].blank?

      r = FetchClientBalances.new(
          client_id: [@client_token[:client_id]],
          balances_to_fetch: {
              GlobalConstant::CriticalChainInteractions.utility_chain_type => {
                  address_uuid: client_token_s[:reserve_uuid],
                  balance_types: [
                      GlobalConstant::BalanceTypes.ost_prime_balance_type,
                      @client_token[:symbol]
                  ]
              },
              GlobalConstant::CriticalChainInteractions.value_chain_type => {
                  address: client_address_data[:ethereum_address_d],
                  balance_types: [
                      GlobalConstant::BalanceTypes.ost_balance_type
                  ]
              }
          }
      ).perform

      return error_with_go_to(
          'fece_3',
          'token_setup_not_complete',
          GlobalConstant::GoTo.economy_planner_step_one
      ) unless r.success?

      @client_balances_data = r.data

      success

    end

    #
    # * Author: Puneet
    # * Date: 31/01/2018
    # * Reviewed By:
    #
    # sets @token_supply_details
    #
    # @return [Result::Base]
    #
    def fetch_token_supply_details

      r = FetchClientTokenSupplyDetails.new(
          client_id: @client_token[:client_id],
          client_token_id: @client_token_id,
          token_symbol: @client_token[:symbol]
      ).perform
      return r unless r.success?

      @token_supply_details = r.data

      success

    end

    # Fetch Pending Transactions
    #
    # * Author: Puneet
    # * Date: 02/02/2018
    # * Reviewed By:
    #
    # Sets @client_token_pending_transactions
    #
    # @return [Result::Base]
    #
    def fetch_pending_transactions

      return success if @client_token_pending_transactions.present?

      @client_token_pending_transactions = CacheManagement::PendingCriticalInteractionIds.new([@client_token_id]).fetch[@client_token_id]

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

      r = SaasApi::OnBoarding::FetchChainInteractionParams.new.perform({client_id: @client_token[:client_id]})
      return r unless r.success?

      chain_interaction_params = r.data.with_indifferent_access
      utility_chain_id = chain_interaction_params[:utility_chain_id]

      data = {
          client_token: @client_token,
          user: @user,
          client_balances: @client_balances_data || {},
          chain_interaction_params: chain_interaction_params,
          oracle_price_points: CacheManagement::OSTPricePoints.new([utility_chain_id]).fetch[utility_chain_id],
          pending_critical_interactions: @client_token_pending_transactions || {},
          token_supply_details: @token_supply_details || {}
      }

      success_with_data(data)

    end

  end

end