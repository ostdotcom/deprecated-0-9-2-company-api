module SaasApi

  module Stake

    class Approve < SaasApi::Base

      # Initialize
      #
      # * Author: Kedar
      # * Date: 29/01/2018
      # * Reviewed By:
      #
      # @return [SaasApi::Stake::Approve]
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
          'post',
          GlobalConstant::SaasApi.approve_for_stake_api_path,
          params
        )
      end

    end

  end

end
