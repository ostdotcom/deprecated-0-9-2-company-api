class Client::SetupController < Client::BaseController

  # Validate if client has this Eth Address as its registered ETH Address
  #
  # * Author: Puneet
  # * Date: 29/01/2018
  # * Reviewed By:
  #
  def validate_eth_address

    service_response = ClientManagement::ValidateEthAddress.new(params).perform

    render_api_response(service_response)

  end

end
