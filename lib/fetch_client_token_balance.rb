class FetchClientTokenBalance

  include Util::ResultHelper

  #
  # * Author: Puneet
  # * Date: 02/02/2018
  # * Reviewed By:
  #
  def initialize(params)

    @client_token = params[:client_token]

  end

  #
  # * Author: Puneet
  # * Date: 02/02/2018
  # * Reviewed By:
  #
  def perform

    success_with_data(
      token_balance: 2, #TODO: Fetch from platform,
      token_to_ost_conversion_rate: @client_token[:conversion_rate]
    )

  end

end