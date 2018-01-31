module Economy

  module TransactionKind

    class List < Economy::TransactionKind::Base

      # Initialize
      #
      # * Author: Puneet
      # * Date: 29/01/2018
      # * Reviewed By:
      #
      # @params [String] client_id (mandatory) - client_id
      #
      # @return [Economy::TransactionKind::List]
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

        @ost_sdk_obj.list({})

      end

    end

  end

end