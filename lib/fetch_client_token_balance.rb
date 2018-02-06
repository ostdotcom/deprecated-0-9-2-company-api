class FetchClientTokenBalance

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
        token_balance: 2 #TODO: Fetch from platform
    }

  end

end