module SaasApi

  module OnBoarding

    class FetchWorkerStatus < SaasApi::Base

      # Initialize
      #
      # * Author: Pankaj
      # * Date: 23/03/2018
      # * Reviewed By:
      #
      # @return [SaasApi::OnBoarding::FetchWorkerStatus]
      #
      def initialize
        super
      end

      # Perform
      #
      # * Author: Pankaj
      # * Date: 23/03/2018
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def perform(params)
        send_request_of_type(
          'post',
          GlobalConstant::SaasApi.fetch_worker_status_path,
          params
        )
      end

    end

  end

end
