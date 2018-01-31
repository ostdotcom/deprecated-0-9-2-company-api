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

        @ost_sdk_obj.create(@params)

      end

    end

  end

end