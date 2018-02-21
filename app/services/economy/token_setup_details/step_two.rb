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

        r = super
        return r unless r.success?

        return error_with_go_to(
            'e_tss_st_1',
            'Setup Step One Not Done',
            'Setup Step One Not Done',
            GlobalConstant::GoTo.economy_planner_step_one
        ) unless is_client_step_one_complete?

        client_address_data = CacheManagement::ClientAddress.new([@client_id]).fetch[@client_id]

        return error_with_data(
            'e_tss_st_2',
            'Client Address not setup.',
            'Client Address not setup.',
            GlobalConstant::ErrorAction.default,
            {}
        ) if client_address_data.blank? || client_address_data[:ethereum_address_d].blank?

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
