module Economy

  module Transaction

    class FetchHistory < ServicesBase

      # Initialize
      #
      # * Author: Puneet
      # * Date: 02/02/2018
      # * Reviewed By:
      #
      # @params [Integer] client_token_id (mandatory) - client token id
      #
      # @return [Economy::Transaction::FetchHistory]
      #
      def initialize(params)

        super

        @client_token_id = @params[:client_token_id]

      end

      # Perform
      #
      # * Author: Puneet
      # * Date: 02/02/2018
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def perform

        success_with_data(client_token_id: @client_token_id)

      end

      private

    end

  end

end
