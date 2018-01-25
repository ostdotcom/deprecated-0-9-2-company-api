module ManagementApi

  module OnBoarding

    class GetRegistrationStatus < ManagementApi::Base

      # Initialize
      #
      # * Author: Kedar
      # * Date: 25/01/2018
      # * Reviewed By:
      #
      # @return [ManagementApi::OnBoarding::GetRegistrationStatus]
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
      # @param [String] transaction_hash (mandatory) - transaction hash of the propose transaction
      #
      # @return [Result::Base]
      #
      def perform(params)
        send_request_of_type(
          'get',
          GlobalConstant::ManagementApi.get_registration_status_api_path,
          params
        )
      end

    end

  end

end
