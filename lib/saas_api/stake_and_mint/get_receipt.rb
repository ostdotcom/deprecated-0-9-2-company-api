module SaasApi

  module StakeAndMint

    class GetReceipt < SaasApi::Base

      # Initialize
      #
      # * Author: Pankaj
      # * Date: 12/02/2018
      # * Reviewed By:
      #
      # @return [SaasApi::StakeAndMint::GetReceipt]
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
          'get',
          GlobalConstant::SaasApi.get_tx_receipt,
          params
        )
      end

    end

  end

end
