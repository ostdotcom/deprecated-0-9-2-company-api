class FetchClientTokenSupplyDetails

  include Util::ResultHelper

  #
  # * Author: Puneet
  # * Date: 02/02/2018
  # * Reviewed By:
  #
  def initialize(params)

    @client_id = params[:client_id]
    @token_symbol = params[:token_symbol]

  end

  #
  # * Author: Puneet
  # * Date: 02/02/2018
  # * Reviewed By:
  #
  def perform

    r = SaasApi::StakeAndMint::FetchStakedAmount.new.perform(client_id: @client_id, token_symbol: @token_symbol)
    tokens_minted = r.success? ? r.data['allTimeStakedAmount'] : 2

    success_with_data(
      tokens_minted: tokens_minted
    )

  end

end