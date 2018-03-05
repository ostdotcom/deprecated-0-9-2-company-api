module SaasApi

  class FetchClientAddressesByUuids < SaasApi::Base

    # Initialize
    #
    # * Author: Pankaj
    # * Date: 19/02/2018
    # * Reviewed By:
    #
    # @return [SaasApi::FetchClientAddressesByUuids]
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
    # @param [Array] uuids (mandatory) - array of uuids
    #
    # @return [Result::Base]
    #
    def perform(params)
      send_request_of_type(
          'get',
          GlobalConstant::SaasApi.get_addresses_by_uuids,
          params
      )
    end

  end

end
