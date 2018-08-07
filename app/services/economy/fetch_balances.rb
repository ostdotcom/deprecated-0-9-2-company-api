module Economy

  class FetchBalances < ServicesBase
    # Initialize
    #
    # * Author: Santhosh
    # * Date: 07/08/2018
    # * Reviewed By:
    #
    # @params [Integer] client_id (mandatory) - client id
    # @params [String Hex] address (mandatory) - address for which the balance is to be fetched
    #
    # @return [Economy::FetchBalances]
    #
    def initialize(params)
      super

      @client_id = @params[:client_id]
      @address = @params[:address]
    end

    # Perform
    #
    # * Author: Santhosh
    # * Date: 07/08/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def perform
      r = validate_and_sanitize
      return r unless r.success?

      fetch
    end

    private

    # Validate and sanitize
    #
    # * Author: Santhosh
    # * Date: 07/08/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def validate_and_sanitize
      r = validate
      return r unless r.success?

      unless Util::CommonValidator.is_ethereum_address?(@address)
        return validation_error(
            'e_fb_1',
            'invalid_api_params',
            ['invalid_eth_address'],
            GlobalConstant::ErrorAction.default
        )
      end

      success
    end

    # Fetch
    #
    # * Author: Santhosh
    # * Date: 07/08/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def fetch
      FetchClientBalances.new(
          client_id: @client_id,
          balances_to_fetch: {
              GlobalConstant::CriticalChainInteractions.value_chain_type => {
                  address: @address,
                  balance_types: [
                      GlobalConstant::BalanceTypes.ost_balance_type,
                      GlobalConstant::BalanceTypes.eth_balance_type
                  ]
              }
          }
      ).perform
    end

  end

end
