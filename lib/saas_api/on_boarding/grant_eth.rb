module SaasApi

  module OnBoarding

    class GrantEth < SaasApi::Base

      # Initialize
      #
      # * Author: Pankaj
      # * Date: 12/02/2018
      # * Reviewed By:
      #
      # @return [SaasApi::OnBoarding::GrantEth]
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
          GlobalConstant::SaasApi.grant_eth_path,
          params
        )
      end

    end

  end

end
