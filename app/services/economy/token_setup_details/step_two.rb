module Economy

  module TokenSetupDetails

    class StepTwo < Economy::TokenSetupDetails::Base

      # Initialize
      #
      # * Author: Puneet
      # * Date: 31/01/2018
      # * Reviewed By:
      #
      # @params [Integer] client_token_id (mandatory) - client token id
      # @params [Integer] user_id (mandatory) - user id
      #
      # @return [Economy::TokenSetupDetails::StepTwo]
      #
      def initialize(params)
        super
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
        super
      end

      private

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

        return error_with_go_to(
            'e_tss_st_1',
            'Setup Step One Not Done',
            'Setup Step One Not Done',
            GlobalConstant::GoTo.economy_planner_step_one
        ) unless is_client_step_one_complete?

        client_address_data = CacheManagement::ClientAddress.new([@client_id]).fetch[@client_id]

        r = fetch_eth_ost_balance(true)
        return error_with_go_to(
            'e_tss_st_2',
            'Setup Step One Not Done',
            'Setup Step One Not Done',
            GlobalConstant::GoTo.economy_planner_step_one
        ) unless r.success?

        if @api_response_data[:client_balances].blank? ||
            @api_response_data[:client_balances][GlobalConstant::BalanceTypes.ost_balance_type].blank?

          return error_with_go_to(
              'e_tss_st_3',
              'OST Not Granted Yet',
              'OST Not Granted Yet',
              GlobalConstant::GoTo.economy_planner_step_one
          ) unless r.success?

        end

        r = super
        return r unless r.success?

        success

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

        super

      end

    end

  end

end
