class FetchClientBalances

  include Util::ResultHelper

  # Initialize
  #
  # * Author: Puneet
  # * Date: 02/02/2018
  # * Reviewed By:
  #
  # @param [Integer] client_id (mandatory) - Client Id for which Api credentials has to be fetched
  # @param [Hash] balances_to_fetch (mandatory) - hash which has value & utility as keys and corresponding data in values
  #
  def initialize(params)

    @client_id = params[:client_id]
    @balances_to_fetch = params[:balances_to_fetch]

    @api_credentials = {}

  end

  # Fetch balances from Platform
  #
  # * Author: Puneet
  # * Date: 01/02/2018
  # * Reviewed By:
  #
  # @return [Result::Base]
  #
  def perform

    r = validate
    return r unless r.success?

    fetch_balances

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

    @balances_to_fetch.each do |chain_type, data|

      case chain_type

        when GlobalConstant::CriticalChainInteractions.utility_chain_type

          return error_with_data(
              'fcb_4',
              'invalid_api_params',
              GlobalConstant::ErrorAction.default
          ) if data[:address_uuid].blank?

          return error_with_data(
              'fcb_5',
              'invalid_api_params',
              GlobalConstant::ErrorAction.default
          ) if data[:balance_types].blank?

        when GlobalConstant::CriticalChainInteractions.value_chain_type

          return error_with_data(
              'fcb_6',
              'invalid_api_params',
              GlobalConstant::ErrorAction.default
          ) if data[:address].blank?

          return error_with_data(
              'fcb_7',
              'invalid_api_params',
              GlobalConstant::ErrorAction.default
          ) if data[:balance_types].blank?

        else
          return error_with_data(
              'fcb_7',
              'invalid_api_params',
              GlobalConstant::ErrorAction.default
          )
      end

    end

    success

  end

  # Fetch balances
  #
  # * Author: Puneet
  # * Date: 01/02/2018
  # * Reviewed By:
  #
  # @return [Result::Base]
  #
  def fetch_balances

    SaasApi::OnBoarding::FetchBalances.new.perform(client_id: @client_id, balances_to_fetch: @balances_to_fetch)

  end

end