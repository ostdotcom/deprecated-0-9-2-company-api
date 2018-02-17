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
        fail 'sub class to implement'
      end

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
            'e_tss_b_1',
            'Token not found.',
            'Token not found.',
            GlobalConstant::ErrorAction.default,
            {}
        ) if @client_token.blank?

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

        !is_client_setup_complete? ? success : error_with_go_to(
            'e_tss_b_2',
            'Setup Complete',
            'Setup Complete',
            GlobalConstant::GoTo.economy_dashboard
        )

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
            oracle_price_points: FetchOraclePricePoints.perform
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
        @i_s_s_c = @client_token[:setup_steps].include?(GlobalConstant::ClientToken.registered_on_vc_setup_step)
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
        @i_s_o_c = @client_token[:setup_steps].include?(GlobalConstant::ClientToken.set_conversion_rate_setup_step)
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

    end

  end

end