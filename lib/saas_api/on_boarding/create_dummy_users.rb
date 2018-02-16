module SaasApi

  module OnBoarding

    class CreateDummyUsers < SaasApi::Base

      # Initialize
      #
      # * Author: Puneet
      # * Date: 14/02/2018
      # * Reviewed By:
      #
      # @return [SaasApi::OnBoarding::CreateDummyUsers]
      #
      def initialize
        super
      end

      # Perform
      #
      # * Author: Puneet
      # * Date: 14/02/2018
      # * Reviewed By:
      #
      # @param [Integer] client_id (mandatory) - Client Id for setup
      # @param [Integer] number_of_users (mandatory) - number_of_users
      #
      # @return [Result::Base]
      #
      def perform(params)
        send_request_of_type(
            'post',
            GlobalConstant::SaasApi.create_dummy_users_path,
            params
        )
      end

    end

  end

end
