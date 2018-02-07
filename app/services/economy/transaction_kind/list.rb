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
      # @param [Integer] client_token_id (mandatory) - Client Token Id
      #
      # @return [Economy::TransactionKind::List]
      #
      def initialize(params)

        super

        @api_response = {}

      end

      # Perform
      #
      # * Author: Puneet
      # * Date: 29/01/2018
      # * Reviewed By:
      #
      # Sets @api_response
      #
      # @return [Result::Base]
      #
      def perform

        r = super
        return r unless r.success?

        r = execute
        return r unless r.success?

        r = fetch_supporting_data
        return r unless r.success?

        success_with_data(@api_response)

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

      # fetch supporting data for pi responce
      #
      # * Author: Puneet
      # * Date: 29/01/2018
      # * Reviewed By:
      #
      # Sets @api_response
      #
      # @return [Result::Base]
      #
      def fetch_supporting_data

        client_token = CacheManagement::ClientToken.new([@client_token_id]).fetch[@client_token_id]

        @api_response.merge!(
            client_token: client_token,
            user: CacheManagement::ClientToken.new([@user_id]).fetch[@user_id],
            client_token_balance: FetchClientTokenBalance.new(client_token: client_token).perform,
            client_ost_balance: FetchClientOstBalance.new(client_id: @client_token[:client_id]).perform
        )

        success

      end

    end

  end

end