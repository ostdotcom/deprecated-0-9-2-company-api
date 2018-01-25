module ManagementApi

  module OnBoarding

    class ProposeBt < ManagementApi::Base

      # Initialize
      #
      # * Author: Kedar
      # * Date: 25/01/2018
      # * Reviewed By:
      #
      # @return [ManagementApi::OnBoarding::ProposeBt]
      #
      def initialize
        super
      end

      # Perform
      #
      # * Author: Kedar
      # * Date: 25/01/2018
      # * Reviewed By:
      #
      # @param [String] sender_address (mandatory) - address which wants to make the propose transaction
      # @param [String] sender_passphrase (mandatory) - sender passphrase
      # @param [String] token_symbol (mandatory) - token symbol
      # @param [String] token_name (mandatory) - token name
      # @param [String] token_conversion_rate (mandatory) - token conversion rate
      #
      # @return [Result::Base]
      #
      def perform(params)
        send_request_of_type(
          'post',
          GlobalConstant::ManagementApi.propose_bt_api_path,
          params
        )
      end

    end

  end

end
