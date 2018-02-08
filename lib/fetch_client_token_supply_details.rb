class FetchClientTokenSupplyDetails

  include Util::ResultHelper

  #
  # * Author: Puneet
  # * Date: 02/02/2018
  # * Reviewed By:
  #
  def initialize(params)

    @client_token_id = params[:client_token_id]

  end

  #
  # * Author: Puneet
  # * Date: 02/02/2018
  # * Reviewed By:
  #
  def perform

    success_with_data(
      tokens_minted: 2,
      tokens_distributed: 2,
    )

  end

end