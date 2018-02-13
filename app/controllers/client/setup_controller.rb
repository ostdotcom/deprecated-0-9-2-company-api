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

  # Get Test OST
  #
  # * Author: Pankaj
  # * Date: 12/02/2018
  # * Reviewed By:
  #
  def get_test_ost

    service_response = ClientManagement::GetTestOst.new(params).perform

    render_api_response(service_response)

  end

end
