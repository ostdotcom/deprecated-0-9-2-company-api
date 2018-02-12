module SaasApi

  module OnBoarding

    class GrantTestOst < SaasApi::Base

      # Initialize
      #
      # * Author: Pankaj
      # * Date: 12/02/2018
      # * Reviewed By:
      #
      # @return [SaasApi::OnBoarding::GetTestOst]
      #
      def initialize
        super
      end

      # Perform
      #
      # * Author: Pankaj
      # * Date: 12/02/2018
      # * Reviewed By:
      #
      # @param [String] ethereum_address (mandatory) - Ethereum address of client to get Test OST.
      # @param [Float] amount (mandatory) - Amount of OST to grant
      #
      # @return [Result::Base]
      #
      def perform(params)
        send_request_of_type(
          'post',
          GlobalConstant::SaasApi.grant_test_ost_path,
          params
        )
      end

    end

  end

end
