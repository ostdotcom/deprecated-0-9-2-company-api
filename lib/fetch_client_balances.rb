class FetchClientBalances

  include Util::ResultHelper

  # Initialize
  #
  # * Author: Puneet
  # * Date: 02/02/2018
  # * Reviewed By:
  #
  # @param [Integer] client_id (mandatory) - Client Id for which Api credentials has to be fetched
  # @param [String] address (mandatory) -address whose balance is to be fetched
  # @param [String] erc20_address (optional) - contract address to fetch BT balance
  #
  def initialize(params)

    @client_id = params[:client_id]
    @address = params[:address]
    @erc20_address = params[:erc20_address]

    @api_credentials = {}

  end

  # Fetch balances from Platform
  #
  # * Author: Puneet
  # * Date: 01/02/2018
  # * Reviewed By:
  #
  # @param [Array] balance_types (mandatory) - balance_types which are to be fetched
  #
  # @return [Result::Base]
  #
  def perform(balance_types)

    r = validate(balance_types)
    return r unless r.success?

    r = fetch_client_api_credentials
    return r unless r.success?

    fetch_balances(balance_types)

  end

  private

  # Fetch balances from Platform
  #
  # * Author: Puneet
  # * Date: 01/02/2018
  # * Reviewed By:
  #
  # @param [Array] balance_types (mandatory) - balance_types which are to be fetched
  #
  # @return [Result::Base]
  #
  def validate(balance_types)

    invalid_balance_types = balance_types - GlobalConstant::BalanceTypes.all_supported_types

    return error_with_data(
      'fcb_1',
       "invalid_balance_types => #{invalid_balance_types}",
       'Something Went Wrong.',
       GlobalConstant::ErrorAction.default,
       {}
    ) if invalid_balance_types.any?

    return error_with_data(
        'fcb_2',
        'missing @erc20_address',
        'Something Went Wrong.',
        GlobalConstant::ErrorAction.default,
        {}
    ) if balance_types.include?(GlobalConstant::BalanceTypes.branded_token_balance_type) && @erc20_address.blank?

    return error_with_data(
        'fcb_3',
        'missing @client_id',
        'Something Went Wrong.',
        GlobalConstant::ErrorAction.default,
        {}
    ) if @client_id.blank?

    success

  end

  # Fetch API credentals
  #
  # * Author: Puneet
  # * Date: 01/02/2018
  # * Reviewed By:
  #
  # @return [Result::Base]
  #
  def fetch_client_api_credentials

    result = CacheManagement::ClientApiCredentials.new([@client_id]).fetch[@client_id]
    return error_with_data(
        'e_tk_b_1',
        "Invalid client.",
        'Something Went Wrong.',
        GlobalConstant::ErrorAction.default,
        {}
    ) if result.blank?

    @api_credentials = result

    success

  end

  # Fetch balances
  #
  # * Author: Puneet
  # * Date: 01/02/2018
  # * Reviewed By:
  #
  # @param [Array] balance_types (mandatory) - balance_types which are to be fetched
  #
  # @return [Result::Base]
  #
  def fetch_balances(balance_types)

    credentials = OSTSdk::Util::APICredentials.new(@api_credentials[:api_key], @api_credentials[:api_secret])
    obj = OSTSdk::Saas::Addresses.new(GlobalConstant::Base.sub_env, credentials)

    params = {balance_types: balance_types, address: @address}
    params[:erc20_address] = @erc20_address if @erc20_address.present?

    obj.fetch_balances(params)

  end

end