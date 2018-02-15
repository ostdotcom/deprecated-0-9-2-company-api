class FetchClientBalances

  include Util::ResultHelper

  # Initialize
  #
  # * Author: Puneet
  # * Date: 02/02/2018
  # * Reviewed By:
  #
  # @param [Integer] client_id (mandatory) - Client Id for which Api credentials has to be fetched
  # @param [String] address_uuid (mandatory) - uuid of address whose balance is to be fetched
  #
  def initialize(params)

    @client_id = params[:client_id]
    @address_uuid = params[:address_uuid]

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

    r = validate
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
  # @return [Result::Base]
  #
  def validate

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

    params = {balance_types: balance_types, address_uuid: @address_uuid}

    obj.fetch_balances(params)

  end

end