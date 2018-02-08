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
      # @param [Integer] user_id (mandatory) - user Id
      #
      # @return [Economy::TransactionKind::List]
      #
      def initialize(params)

        super

        @user_id = @params[:user_id]
        @client_token_id = @params[:client_token_id]

        @api_response_data = {}

      end

      # Perform
      #
      # * Author: Puneet
      # * Date: 29/01/2018
      # * Reviewed By:
      #
      # Sets @api_response_data
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

        success_with_data(@api_response_data)

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

        r = @ost_sdk_obj.list({})
        return r unless r.success?

        @api_response_data = r.data

        success

      end

      # fetch supporting data for pi responce
      #
      # * Author: Puneet
      # * Date: 29/01/2018
      # * Reviewed By:
      #
      # Sets @api_response_data
      #
      # @return [Result::Base]
      #
      def fetch_supporting_data

        r = Util::FetchEconomyCommonEntities.new(user_id: @user_id, client_token_id: @client_token_id).perform
        return r unless r.success?

        @api_response_data.merge!(r.data)

        success

      end

    end

  end

end