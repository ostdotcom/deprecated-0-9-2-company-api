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
      # @params [String] id (mandatory) - client_transaction_id
      # @params [String] arbitrary_amount (mandatory) - boolean determining if this tx has fixed amount
      # @params [String] arbitrary_commission (mandatory) - boolean determining if this tx has fixed commission
      # @params [String] name (optional) - name of transaction
      # @params [String] kind (optional) - kind of transaction
      # @params [String] currency (optional) - value_currency_type of transaction
      # @params [String] amount (optional) - value_in_usd of transaction
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
puts @params
        @ost_sdk_obj.edit(@params.to_hash)

      end

    end

  end

end