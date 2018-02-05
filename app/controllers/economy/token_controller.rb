class Economy::TokenController < Economy::BaseController

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

  # Record a transaction in our DB which was used to transfer OST from Client's Address to Our Staker's Address
  #
  # * Author: Puneet
  # * Date: 02/02/2018
  # * Reviewed By:
  #
  def log_transfer_to_staker
    service_response = Economy::LogTransferToStaker.new(params).perform
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

  # Get Setup Status
  #
  # * Author: Puneet
  # * Date: 31/01/2018
  # * Reviewed By:
  #
  def get_setup_details
    service_response = Economy::GetTokenSetupDetails.new(params).perform
    render_api_response(service_response)
  end

end
