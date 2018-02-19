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
  # * Reviewed By: Sunil
  #
  def stake_and_mint
    service_response = Economy::StakeAndMint.new(params).perform
    render_api_response(service_response)
  end

  # Get Step One Status
  #
  # * Author: Puneet
  # * Date: 31/01/2018
  # * Reviewed By:
  #
  def get_step_one_details
    service_response = Economy::TokenSetupDetails::StepOne.new(params).perform
    render_api_response(service_response)
  end

  # Get Setup Status
  #
  # * Author: Puneet
  # * Date: 31/01/2018
  # * Reviewed By:
  #
  def get_step_two_details
    service_response = Economy::TokenSetupDetails::StepTwo.new(params).perform
    render_api_response(service_response)
  end

  # Get Supply Status
  #
  # * Author: Puneet
  # * Date: 31/01/2018
  # * Reviewed By:
  #
  def get_step_three_details
    service_response = Economy::TokenSetupDetails::StepThree.new(params).perform
    render_api_response(service_response)
  end

  #
  # * Author: Puneet
  # * Date: 31/01/2018
  # * Reviewed By:
  #
  def get_dashboard_details
    service_response = Economy::GetDashboardDetails.new(params).perform
    render_api_response(service_response)
  end

  # Get Token Supply Details
  #
  # * Author: Puneet
  # * Date: 31/01/2018
  # * Reviewed By:
  #
  def get_supply_details
    service_response = Economy::GetTokenSupplyDetails.new(params).perform
    render_api_response(service_response)
  end

end
