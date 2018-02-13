module SaasApi

  module OnBoarding

    class SetupBt < SaasApi::Base

      # Initialize
      #
      # * Author: Pankaj
      # * Date: 14/02/2018
      # * Reviewed By:
      #
      # @return [SaasApi::OnBoarding::SetupBt]
      #
      def initialize
        super
      end

      # Perform
      #
      # * Author: Pankaj
      # * Date: 14/02/2018
      # * Reviewed By:
      #
      # @param [String] symbol (mandatory) - Branded Token Symbol for which setup has to be done
      # @param [Integer] client_id (mandatory) - Client Id for setup
      #
      # @return [Result::Base]
      #
      def perform(params)
        send_request_of_type(
          'post',
          GlobalConstant::SaasApi.setup_token_path,
          params
        )
      end

    end

  end

end
