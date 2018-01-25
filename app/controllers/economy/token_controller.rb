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

  # plan token action
  #
  # * Author: Kedar
  # * Date: 24/01/2018
  # * Reviewed By:
  #
  def plan_token
    service_response = Economy::Plan.new(params).perform
    render_api_response(service_response)
  end

  # stake and mint
  #
  # * Author: Kedar
  # * Date: 24/01/2018
  # * Reviewed By:
  #
  def stake_and_mint
    service_response = Economy::StakeAndMint.new(params).perform
    render_api_response(service_response)
  end

end
