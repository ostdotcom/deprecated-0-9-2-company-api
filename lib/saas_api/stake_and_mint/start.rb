module SaasApi

  module StakeAndMint

    class Start < SaasApi::Base

      # Initialize
      #
      # * Author: Puneet
      # * Date: 20/03/2018
      # * Reviewed By:
      #
      # @return [SaasApi::StakeAndMint::Start]
      #
      def initialize
        super
      end

      # Perform
      #
      # * Author: Puneet
      # * Date: 20/03/2018
      # * Reviewed By:
      #
      # @param [String] token_symbol (mandatory) - token_symbol
      # @param [Integer] client_id (mandatory) - client_id
      # @param [String] bt_to_mint (mandatory) - amount of BT to be minted as per FE
      # @param [String] st_prime_to_mint (mandatory) -amount of ST Prime to be minted as per FE
      # @param [String] client_eth_address (mandatory) - client's metamask eth address of VC
      # @param [String] transfer_to_staker_tx_hash (mandatory) - tx hash via which client transferred OST to staker
      #
      # @return [Result::Base]
      #
      def perform(params = {})
        send_request_of_type(
            'post',
            GlobalConstant::SaasApi.start_stake,
            params
        )
      end

    end

  end

end
