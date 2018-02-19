module SaasApi

  class FetchClientUsersDetails < SaasApi::Base

    # Initialize
    #
    # * Author: Pankaj
    # * Date: 19/02/2018
    # * Reviewed By:
    #
    # @return [SaasApi::FetchClientUsersDetails]
    #
    def initialize
      super
    end

    # Perform
    #
    # * Author: Pankaj
    # * Date: 19/02/2018
    # * Reviewed By:
    #
    # @param [Integer] client_id (mandatory) - Client Id for fetch user details
    # @param [Array] ethereum_addresses (mandatory) - Ethereum Addresses of Users to fetch data for
    #
    # @return [Result::Base]
    #
    def perform(params)
      send_request_of_type(
          'get',
          GlobalConstant::SaasApi.get_user_details_path,
          params
      )
    end

  end

end
