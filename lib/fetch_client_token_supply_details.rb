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

    # r = SaasApi::StakeAndMint::FetchStakedAmount.new.perform({simple_stake_contract_address: ''})
    # tokens_minted = r.success? ? r.data['allTimeStakedAmount'] : 2

    success_with_data(
      tokens_minted: 2
    )

  end

end