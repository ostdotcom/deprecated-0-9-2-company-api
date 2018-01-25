module Economy

  class StakeAndMint < ServicesBase

    # Initialize
    #
    # * Author: Kedar
    # * Date: 24/01/2018
    # * Reviewed By:
    #
    # @params [Integer] client_id (mandatory) - client id
    # @params [String] token_name (mandatory) - token name
    #
    # @return [Economy::StakeAndMint]
    #
    def initialize(params)
      super

      @client_id = @params[:client_id]
      @token_name = @params[:token_name]

      @client_token = nil
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

      enqueue_job

      success

    end

    private

    # Validate and sanitize
    #
    # * Author: Kedar
    # * Date: 24/01/2018
    # * Reviewed By:
    #
    # Sets @client_token
    #
    # @return [Result::Base]
    #
    def validate_and_sanitize

      r = validate
      return r unless r.success?

      # sanitize
      @token_name = @token_name.to_s.strip

      @client_token = ClientToken.where(
        name: @token_name,
        client_id: @client_id,
        status: GlobalConstant::ClientToken.active_status
      ).first

      return error_with_data(
        'e_sam_1',
        'Token not found.',
        'Token not found.',
        GlobalConstant::ErrorAction.default,
        {}
      ) unless @client_token.present?

      return error_with_data(
        'e_sam_2',
        'Economy not planned.',
        'Economy not planned.',
        GlobalConstant::ErrorAction.default,
        {}
      ) unless @client_token.conversion_rate.to_f > 0

      success

    end

    # Enqueue job
    #
    # * Author: Kedar
    # * Date: 24/01/2018
    # * Reviewed By:
    #
    def enqueue_job
      BgJob.enqueue(
        ProposeBtJob,
        {
          client_id: @client_id,
          token_symbol: @client_token.symbol,
          token_name: @client_token.name,
          token_conversion_rate: @client_token.conversion_rate
        }
      )
    end

  end

end
