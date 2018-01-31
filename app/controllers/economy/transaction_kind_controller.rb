class Economy::TransactionKindController < Economy::BaseController

  # create transaction kind
  #
  # * Author: Puneet
  # * Date: 29/01/2018
  # * Reviewed By:
  #
  def create
    service_response = Economy::TransactionKind::Create.new(params).perform
    render_api_response(service_response)
  end

  # edit transaction
  #
  # * Author: Puneet
  # * Date: 29/01/2018
  # * Reviewed By:
  #
  def edit
    service_response = Economy::TransactionKind::Edit.new(params).perform
    render_api_response(service_response)
  end

  # create transaction
  #
  # * Author: Puneet
  # * Date: 29/01/2018
  # * Reviewed By:
  #
  def list
    service_response = Economy::TransactionKind::List.new(params).perform
    render_api_response(service_response)
  end

end
