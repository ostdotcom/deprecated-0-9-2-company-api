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

  # Fetch API Credentials for a  client
  #
  # * Author: Puneet
  # * Date: 29/01/2018
  # * Reviewed By:
  #
  def fetch_api_credentials

    # Return error if this request was not a XHR request
    if request.xhr?.nil?
      service_response = Result::Base.error(
        error: 'sc_1',
        error_message: 'not allowed',
        http_code: GlobalConstant::ErrorCode.forbidden
      )
    else
      service_response = ClientManagement::GetClientApiCredentials.new(params).perform
    end

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

  # Get Test Eth
  #
  # * Author: Pankaj
  # * Date: 16/02/2018
  # * Reviewed By:
  #
  def get_test_eth

    service_response = ClientManagement::GetTestEth.new(params).perform

    render_api_response(service_response)

  end

end
