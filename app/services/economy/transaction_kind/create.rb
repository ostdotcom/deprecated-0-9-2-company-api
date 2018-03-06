module Economy

  module TransactionKind

    class Create < Economy::TransactionKind::Base

      # Initialize
      #
      # * Author: Puneet
      # * Date: 29/01/2018
      # * Reviewed By:
      #
      # @params [Integer] client_id (mandatory) - client_id
      # @params [String] name (mandatory) - name of transaction
      # @params [String] kind (mandatory) - kind of transaction
      # @params [String] value_currency_type (mandatory) - value_currency_type of transaction
      # @params [String] value_in_usd (mandatory) - value_in_usd of transaction
      # @params [String] value_in_bt (mandatory) - value_in_bt of transaction
      # @params [String] commission_percent (mandatory) - commission_percent of transaction
      # @params [Integer] use_price_oracle (mandatory) - use prie oracle
      #
      # @return [Economy::TransactionKind::Base]
      #
      def initialize(params)

        super

        @client_token_id = @params[:client_token_id]

      end

      # Perform
      #
      # * Author: Puneet
      # * Date: 29/01/2018
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def perform

        r = super
        return r unless r.success?

        r = sanitize_create_edit_params!
        return r unless r.success?

        response = execute

        unless response.success?
          return exception_with_data(
            Exception.new('saas call failed'),
            's_e_tk_c_1',
            'saas call failed',
            'saas call failed',
            GlobalConstant::ErrorAction.default,
            response.to_hash
          )
        end

        edit_client_token_status

        response

      end


      private

      # execute
      #
      # * Author: Puneet
      # * Date: 29/01/2018
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def execute

        @ost_sdk_obj.create(@params)

      end

      # Edit client token status
      #
      # * Author: Puneet
      # * Date: 29/01/2018
      # * Reviewed By:
      #
      def edit_client_token_status
        bit_value = ClientToken.setup_steps_config[GlobalConstant::ClientToken.configure_transactions_setup_step]
        ClientToken.where(id: @client_token_id).
          where("setup_steps is NULL OR (setup_steps & #{bit_value} = 0)").update_all("setup_steps = setup_steps | #{bit_value}")
        CacheManagement::ClientToken.new([@client_token_id]).clear
      end

    end

  end

end