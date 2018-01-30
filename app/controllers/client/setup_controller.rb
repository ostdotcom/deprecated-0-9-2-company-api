class Client::SetupController < Client::BaseController

  # Setup Eth Address
  #
  # * Author: Puneet
  # * Date: 29/01/2018
  # * Reviewed By:
  #
  def setup_eth_address

    service_response = ClientManagement::SetupEthAddress.new(params).perform

    render_api_response(service_response)

  end

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
