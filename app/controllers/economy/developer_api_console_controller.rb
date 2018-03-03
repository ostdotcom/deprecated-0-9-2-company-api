class Economy::DeveloperApiConsoleController < Economy::BaseController

  # Fetch Develper API Console details
  #
  # * Author: Puneet
  # * Date: 29/01/2018
  # * Reviewed By:
  #
  def fetch
    service_response = Economy::GetDeveloperConsoleDetails.new(params).perform
    render_api_response(service_response)
  end

end