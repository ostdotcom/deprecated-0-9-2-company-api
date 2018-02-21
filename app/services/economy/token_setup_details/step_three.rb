module Economy

  module TokenSetupDetails

    class StepThree < Economy::TokenSetupDetails::Base

      # Initialize
      #
      # * Author: Puneet
      # * Date: 31/01/2018
      # * Reviewed By:
      #
      # @params [Integer] client_token_id (mandatory) - client token id
      # @params [Integer] user_id (mandatory) - user id
      #
      # @return [Economy::TokenSetupDetails::StepThree]
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

        r = super
        return r unless r.success?

        if is_client_step_one_complete? && is_client_step_two_complete?
          success
        elsif is_client_step_one_complete?
          error_with_go_to(
              'e_tss_sth_1',
              'Setup Step Two Not Done',
              'Setup Step Two Not Done',
              GlobalConstant::GoTo.economy_planner_step_two
          )
        else
          error_with_go_to(
              'e_tss_sth_2',
              'Setup Step One Not Done',
              'Setup Step One Not Done',
              GlobalConstant::GoTo.economy_planner_step_one
          )
        end

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

        r = super
        return r unless r.success?

        pending_critical_interaction_ids = CacheManagement::PendingCriticalInteractionIds.new([@client_token_id]).fetch[@client_token_id]

        pending_critical_interaction_id = pending_critical_interaction_ids.blank? ? nil :
                                              pending_critical_interaction_ids[GlobalConstant::CriticalChainInteractions.stake_bt_started_activity_type]

        if pending_critical_interaction_id.present?
          @api_response_data[:pending_critical_interaction_id] = pending_critical_interaction_id
        end

        @api_response_data[:client_token_planner] = CacheManagement::ClientTokenPlanner.new([@client_token_id]).fetch[@client_token_id]

        fetch_eth_ost_balance

      end

    end

  end

end
