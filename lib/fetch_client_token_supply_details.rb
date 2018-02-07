class FetchClientTokenSupplyDetails

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

    {
        tokens_minted: 2,
        tokens_distributed: 2,
    }

  end

end