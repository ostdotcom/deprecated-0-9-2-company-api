module Economy

  module TokenSetupDetails

    class Base < ServicesBase

      # Initialize
      #
      # * Author: Puneet
      # * Date: 31/01/2018
      # * Reviewed By:
      #
      # @params [Integer] client_token_id (mandatory) - client token id
      # @params [Integer] user_id (mandatory) - user id
      #
      # @return [Economy::TokenSetupDetails::Base]
      #
      def initialize(params)

        super

        @user_id = @params[:user_id]
        @client_token_id = @params[:client_token_id]

        @client_token = nil
        @client_id = nil
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

        r = validate_step
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
        return validation_error(
            'e_tss_b_1',
            'invalid_api_params',
            ['invalid_client_token_id'],
            GlobalConstant::ErrorAction.default
        ) if @client_token.blank?

        @client_id = @client_token[:client_id]

        success

      end

      # Verify if client can view this page
      # If not set appropriate error go to
      #
      # * Author: Puneet
      # * Date: 31/01/2018
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def validate_step

        if is_client_setup_complete?

          pending_critical_interactions[GlobalConstant::CriticalChainInteractions.propose_bt_activity_type] || has_zero_bt? ?
              success : error_with_go_to(
              'e_tss_b_2',
              'token_setup_complete',
              GlobalConstant::GoTo.economy_dashboard
          )

        else

          success

        end

      end

      #
      # * Author: Puneet
      # * Date: 31/01/2018
      # * Reviewed By:
      #
      # Sets @api_response_data
      #
      # @return [Result::Base]
      #
      def fetch_supporting_data

        @api_response_data.merge!(
            user: CacheManagement::User.new([@user_id]).fetch[@user_id],
            client_token: @client_token,
            oracle_price_points: FetchOraclePricePoints.perform,
            pending_critical_interactions: pending_critical_interactions
        )

        success

      end

      # Is client's setup complete ?
      #
      # * Author: Puneet
      # * Date: 31/01/2018
      # * Reviewed By:
      #
      # @return [Boolean]
      #
      def is_client_setup_complete?
        return @i_s_s_c unless @i_s_s_c.nil?
        @i_s_s_c = @client_token[:setup_steps].include?(GlobalConstant::ClientToken.setup_complete_step)
      end

      # Is client's setup complete ?
      #
      # * Author: Puneet
      # * Date: 31/01/2018
      # * Reviewed By:
      #
      # @return [Boolean]
      #
      def is_client_step_one_complete?
        return @i_s_o_c unless @i_s_o_c.nil?
        @i_s_o_c = @client_token[:setup_steps].include?(GlobalConstant::ClientToken.token_worth_in_usd_setup_step)
      end

      # Is client's setup complete ?
      #
      # * Author: Puneet
      # * Date: 31/01/2018
      # * Reviewed By:
      #
      # @return [Boolean]
      #
      def is_client_step_two_complete?
        return @i_s_t_c unless @i_s_t_c.nil?
        @i_s_t_c = @client_token[:setup_steps].include?(GlobalConstant::ClientToken.configure_transactions_setup_step)
      end

      # Sub classes to fetch required data
      #
      # * Author: Puneet
      # * Date: 31/01/2018
      # * Reviewed By:
      #
      # Sets @api_response_data
      #
      # @return [Result::Base]
      #
      def fetch_setup_details

        r = SaasApi::OnBoarding::FetchChainInteractionParams.new.perform({client_id: @client_id})
        return r unless r.success?

        @api_response_data[:client_token_planner] = CacheManagement::ClientTokenPlanner.new([@client_token_id]).fetch[@client_token_id]
        @api_response_data[:chain_interaction_params] = r.data.with_indifferent_access

        success

      end

      # fetch OST & ETH Balance from SAAS
      #
      # * Author: Puneet
      # * Date: 31/01/2018
      # * Reviewed By:
      #
      # Sets @api_response_data
      #
      # @return [Result::Base]
      #
      def fetch_eth_ost_balance(fail_if_addr_not_setup = true)

        client_address_data = CacheManagement::ClientAddress.new([@client_id]).fetch[@client_id]

        if client_address_data.blank? || client_address_data[:ethereum_address_d].blank?

          r = fail_if_addr_not_setup ? error_with_go_to(
              'e_tss_b_2',
              'token_setup_not_complete',
              GlobalConstant::GoTo.economy_planner_step_one
          ) : success

          return r

        end

        balances_to_fetch = {
            GlobalConstant::CriticalChainInteractions.value_chain_type => {
                address: client_address_data[:ethereum_address_d],
                balance_types: [
                    GlobalConstant::BalanceTypes.ost_balance_type,
                    GlobalConstant::BalanceTypes.eth_balance_type
                ]
            }
        }

        client_token_s = CacheManagement::ClientTokenSecure.new([@client_token_id]).fetch[@client_token_id]

        balances_to_fetch[GlobalConstant::CriticalChainInteractions.utility_chain_type] = {
            address_uuid: client_token_s[:reserve_uuid],
            balance_types: [@client_token[:symbol]]
        } if client_token_s[:token_erc20_address].present?

        r = FetchClientBalances.new(
            client_id: @client_id,
            balances_to_fetch: balances_to_fetch
        ).perform

        return error_with_go_to(
            'e_tss_b_2',
            'token_setup_not_complete',
            GlobalConstant::GoTo.economy_planner_step_one
        ) unless r.success?

        @api_response_data[:client_balances] = r.data

        balances = @api_response_data[:client_balances]['balances']

        ost_balance_str = balances[GlobalConstant::BalanceTypes.ost_balance_type]
        ost_balance = ost_balance_str.present? ? BigDecimal.new(ost_balance_str) : ost_balance_str
        if ost_balance.blank? || ost_balance == 0
          return error_with_go_to(
              'e_tss_b_3',
              'token_setup_not_complete',
              GlobalConstant::GoTo.economy_planner_step_one
          )
        end

        eth_balance_str = balances[GlobalConstant::BalanceTypes.eth_balance_type]
        eth_balance = eth_balance_str.present? ? BigDecimal.new(eth_balance_str) : eth_balance_str
        if eth_balance.blank? || eth_balance == 0
          return error_with_go_to(
              'e_tss_b_3',
              'token_setup_not_complete',
              GlobalConstant::GoTo.economy_planner_step_one
          )
        end

        success

      end

      # fetch if a transaction to propose & stake / mint is pending execution
      #
      # * Author: Puneet
      # * Date: 31/01/2018
      # * Reviewed By:
      #
      # @return [Integer]
      #
      def pending_critical_interactions
        @p_c_i_id ||= begin
          CacheManagement::PendingCriticalInteractionIds.new([@client_token_id]).fetch[@client_token_id]
        end
      end

      # Client Has Zero BT ?
      #
      # * Author: Puneet
      # * Date: 31/01/2018
      # * Reviewed By:
      #
      # @return [Boolean]
      #
      def has_zero_bt?
        balances = @api_response_data[:client_balances].present? ? @api_response_data[:client_balances]['balances'] : {}
        balances.blank? || balances[@client_token[:symbol]].blank? ||
            BigDecimal.new(balances[@client_token[:symbol]]) == 0
      end

    end

  end

end