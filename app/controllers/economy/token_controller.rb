class Economy::TokenController < Economy::BaseController

  # create token action
  #
  # * Author: Kedar
  # * Date: 24/01/2018
  # * Reviewed By:
  #
  def create_token
    service_response = Economy::CreateToken.new(params).perform
    render_api_response(service_response)
  end

end