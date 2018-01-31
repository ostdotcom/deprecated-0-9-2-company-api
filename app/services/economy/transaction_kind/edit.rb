module Economy

  module TransactionKind

    class Edit < Economy::TransactionKind::Base

      # Initialize
      #
      # * Author: Puneet
      # * Date: 29/01/2018
      # * Reviewed By:
      #
      # @params [String] client_id (mandatory) - client_id
      # @params [String] client_transaction_id (mandatory) - client_transaction_id
      # @params [String] name (optional) - name of transaction
      # @params [String] kind (optional) - kind of transaction
      # @params [String] value_currency_type (optional) - value_currency_type of transaction
      # @params [String] value_in_usd (optional) - value_in_usd of transaction
      # @params [String] value_in_bt (optional) - value_in_bt of transaction
      # @params [String] commission_percent (optional) - commission_percent of transaction
      #
      # @return [Economy::TransactionKind::Base]
      #
      def initialize(params)

        super

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

        execute

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

        @ost_sdk_obj.edit(@params)

      end

    end

  end

end