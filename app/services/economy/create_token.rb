module Economy

  class CreateToken < ServicesBase

    # Initialize
    #
    # * Author: Kedar
    # * Date: 24/01/2018
    # * Reviewed By:
    #
    # @params [Integer] client_id (mandatory) - client id
    # @params [String] token_name (mandatory) - token name
    # @params [String] token_symbol (mandatory) - token symbol
    #
    # @return [Economy::CreateToken]
    #
    def initialize(params)
      super

      @client_id = @params[:client_id]
      @token_name = @params[:token_name]
      @token_symbol = @params[:token_symbol]
    end

    # Perform
    #
    # * Author: Kedar
    # * Date: 24/01/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def perform

      r = validate_and_sanitize
      return r unless r.success?

      create

      success

    end

    private

    # Validate and sanitize
    #
    # * Author: Kedar
    # * Date: 24/01/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def validate_and_sanitize

      r = validate
      return r unless r.success?

      # sanitize
      @token_name = @token_name.to_s.strip

      @token_symbol = @token_symbol.to_s.strip

      return error_with_data(
        'e_ct_1',
        'Token name already exists.',
        'Token name already exists.',
        GlobalConstant::ErrorAction.default,
        {}
      ) if ClientToken.where(name: @token_name, status: GlobalConstant::ClientToken.active_status).first.present?

      return error_with_data(
        'e_ct_2',
        'Token symbol already exists.',
        'Token symbol already exists.',
        GlobalConstant::ErrorAction.default,
        {}
      ) if ClientToken.where(symbol: @token_symbol, status: GlobalConstant::ClientToken.active_status).first.present?

      success

    end

    # create
    #
    # * Author: Kedar
    # * Date: 24/01/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def create

      ct = ClientToken.new(
        client_id: @client_id,
        name: @token_name,
        symbol: @token_symbol,
        company_managed_addresses_id: 0,
        status: GlobalConstant::ClientToken.active_status
      )

      ct.save!

      success

    end

  end

end
