class Economy::TransactionController < Economy::BaseController

  # execute a random transaction on a token
  #
  # * Author: Puneet
  # * Date: 29/01/2018
  # * Reviewed By:
  #
  def simulate
    service_response = Economy::Transaction::Simulate.new(params).perform
    render_api_response(service_response)
  end

  # get history of transactions performed by client on a token
  #
  # * Author: Puneet
  # * Date: 29/01/2018
  # * Reviewed By:
  #
  def fetch_history
    service_response = Economy::Transaction::FetchHistory.new(params).perform
    render_api_response(service_response)
  end

  # Fetch details of transactions of a user
  #
  # * Author: Puneet
  # * Date: 29/01/2018
  # * Reviewed By:
  #
  def fetch_detail
    service_response = Economy::Transaction::FetchDetail.new(params).perform
    render_api_response(service_response)
  end

end
