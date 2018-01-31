module Economy

  class GetTokenSetupStatus < ServicesBase

    # Initialize
    #
    # * Author: Puneet
    # * Date: 31/01/2018
    # * Reviewed By:
    #
    # @params [Integer] client_id (mandatory) - client id
    #
    # @return [Economy::PlaGetTokenSetupStatusn]
    #
    def initialize(params)

      super

      @client_id = @params[:client_id]
      @client_token = nil

    end

    # Perform
    #
    # * Author: Puneet
    # * Date: 31/01/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def perform

      r = validate
      return r unless r.success?

      r = fetch_client_token
      return r unless r.success?

      success_with_data(steps_performed: ClientToken.get_bits_set_for_setup_steps(@client_token.setup_steps))

    end

    private

    #
    # * Author: Puneet
    # * Date: 31/01/2018
    # * Reviewed By:
    #
    # Sets @client_token
    #
    def fetch_client_token

      @client_token = ClientToken.where(client_id: @client_id).last
      return error_with_data(
          'e_gtss_1',
          'Token not found.',
          'Token not found.',
          GlobalConstant::ErrorAction.default,
          {}
      ) if @client_token.blank?

      success

    end

  end

end
