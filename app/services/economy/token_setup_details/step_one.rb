module Economy

  module TokenSetupDetails

    class StepOne < Economy::TokenSetupDetails::Base

      # Initialize
      #
      # * Author: Puneet
      # * Date: 31/01/2018
      # * Reviewed By:
      #
      # @params [Integer] client_token_id (mandatory) - client token id
      # @params [Integer] user_id (mandatory) - user id
      #
      # @return [Economy::TokenSetupDetails::StepOne]
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
        super
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

        # set this with {} if step one not complete or fetch
        @api_response_data[:client_token_planner] = !is_client_step_one_complete? ? {} :
            CacheManagement::ClientTokenPlanner.new([@client_token_id]).fetch[@client_token_id]

        fetch_eth_ost_balance(false)

      end

    end

  end

end
