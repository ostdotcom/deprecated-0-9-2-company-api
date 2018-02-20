module SaasApi

  module Transaction

    class Simulate < SaasApi::Base

      # Initialize
      #
      # * Author: Aman
      # * Date: 17/02/2018
      # * Reviewed By:
      #
      # @return [SaasApi::Transaction::Simulate]
      #
      def initialize
        super
      end

      # Perform
      #
      # * Author: Aman
      # * Date: 17/02/2018
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def perform(params = {})
        send_request_of_type(
          'post',
          GlobalConstant::SaasApi.simulate_transaction,
          params
        )
      end

    end

  end

end
