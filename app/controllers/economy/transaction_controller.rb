class Economy::TransactionController < Economy::BaseController

  # execute a random transaction on a token
  #
  # * Author: Puneet
  # * Date: 29/01/2018
  # * Reviewed By:
  #
  def execute
    service_response = Economy::Transaction::Execute.new(params).perform
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

end
