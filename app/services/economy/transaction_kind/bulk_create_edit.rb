module Economy

  module TransactionKind

    class BulkCreateEdit < Economy::TransactionKind::Base

      # Initialize
      #
      # * Author: Alpesh
      # * Date: 12/02/2018
      # * Reviewed By:
      #
      # @params [Integer] client_id (mandatory) - client_id
      # @params [Hash] transaction_kinds - Hash of all transaction_kinds to be created or edited
      #
      # @return [Economy::TransactionKind::Base]
      #
      def initialize(params)

        super

        @transaction_kinds = @params[:transaction_kinds]

        @response_hash = {}

      end

      # Perform
      #
      # * Author: Alpesh
      # * Date: 12/02/2018
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

        return_response
      end

      private

      # execute
      #
      # * Author: Alpesh
      # * Date: 12/02/2018
      # * Reviewed By:
      #
      # Sets @response_hash
      #
      def execute

        @transaction_kinds.each do |key, transaction_kind|
          t_k = transaction_kind.permit(:client_transaction_id, :name, :kind, :value_currency_type, :value_in_bt, :commission_percent, :value_in_usd, :use_price_oracle)
          if transaction_kind[:client_transaction_id].present?
            response_hash = @ost_sdk_obj.edit(t_k.to_h)
          else
            response_hash = @ost_sdk_obj.create(t_k.to_h)
          end
          @response_hash[key] = response_hash.to_json
        end

      end

      # return_response
      #
      # * Author: Alpesh
      # * Date: 12/02/2018
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def return_response
        success_with_data(@response_hash)
      end

    end

  end

end