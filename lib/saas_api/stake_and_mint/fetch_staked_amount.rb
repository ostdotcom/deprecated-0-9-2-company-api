module SaasApi

  module StakeAndMint

    class FetchStakedAmount < SaasApi::Base

      # Initialize
      #
      # * Author: Puneet
      # * Date: 12/02/2018
      # * Reviewed By:
      #
      # @return [SaasApi::StakeAndMint::FetchStakedAmount]
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
      # @return [Result::Base]
      #
      def perform(params = {})
        send_request_of_type(
            'get',
            GlobalConstant::SaasApi.get_staked_amount,
            params
        )
      end

    end

  end

end
