module SaasApi

  module OnBoarding

    class AssignStrategies < SaasApi::Base

      # Initialize
      #
      # * Author: Puneet
      # * Date: 14/02/2018
      # * Reviewed By:
      #
      # @return [SaasApi::OnBoarding::AssignStrategies]
      #
      def initialize
        super
      end

      # Perform
      #
      # * Author: Puneet
      # * Date: 14/02/2018
      # * Reviewed By:
      #
      # @param [Integer] client_id (mandatory) - Client Id for AssignStrategies
      #
      # @return [Result::Base]
      #
      def perform(params)
        send_request_of_type(
            'post',
            GlobalConstant::SaasApi.assign_strategies_path,
            params
        )
      end

    end

  end

end
