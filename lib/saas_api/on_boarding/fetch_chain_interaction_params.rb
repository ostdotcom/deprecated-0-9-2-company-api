module SaasApi

  module OnBoarding

    class FetchChainInteractionParams < SaasApi::Base

      # Initialize
      #
      # * Author: Puneet
      # * Date: 21/02/2018
      # * Reviewed By:
      #
      # @return [SaasApi::OnBoarding::FetchChainInteractionParams]
      #
      def initialize
        super
      end

      # Perform
      #
      # * Author: Puneet
      # * Date: 21/02/2018
      # * Reviewed By:
      #
      # @param [Integer] client_id (mandatory) - Client Id
      #
      # @return [Result::Base]
      #
      def perform(params)
        send_request_of_type(
            'get',
            GlobalConstant::SaasApi.get_chain_interaction_params_path,
            params
        )
      end

    end

  end

end
