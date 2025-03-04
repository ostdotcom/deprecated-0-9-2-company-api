class FetchClientTokenSupplyDetails

  include Util::ResultHelper

  #
  # * Author: Puneet
  # * Date: 02/02/2018
  # * Reviewed By:
  #
  def initialize(params)

    @client_id = params[:client_id]
    @client_token_id = params[:client_token_id]
    @token_symbol = params[:token_symbol]

  end

  #
  # * Author: Puneet
  # * Date: 02/02/2018
  # * Reviewed By:
  #
  def perform

    r = SaasApi::StakeAndMint::FetchStakedAmount.new.perform(client_id: @client_id, token_symbol: @token_symbol)
    return error_with_go_to(
        'l_fctsd_1',
        'token_setup_not_complete',
        GlobalConstant::GoTo.economy_planner_step_three
    ) unless r.success?

    ost_staked = r.data['allTimeStakedAmount']
    return error_with_data(
        'l_fctsd_2',
        'something_went_wrong',
        GlobalConstant::ErrorAction.default
    ) if ost_staked.blank?

    ost_staked = BigDecimal.new(ost_staked)

    client_token = CacheManagement::ClientToken.new([@client_token_id]).fetch[@client_token_id]
    ost_to_bt = BigDecimal.new(client_token[:conversion_factor])

    tokens_minted = ost_to_bt * ost_staked

    success_with_data(
      tokens_minted: tokens_minted
    )

  end

end