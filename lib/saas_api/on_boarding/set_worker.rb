module SaasApi

  module OnBoarding

    class SetWorker < SaasApi::Base

      # Initialize
      #
      # * Author: Alpesh
      # * Date: 21/02/2018
      # * Reviewed By:
      #
      # @return [SaasApi::OnBoarding::SetWorker]
      #
      def initialize
        super
      end

      # Perform
      #
      # * Author: Alpesh
      # * Date: 21/02/2018
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def perform(params)
        send_request_of_type(
          'post',
          GlobalConstant::SaasApi.set_worker_path,
          params
        )
      end

    end

  end

end
