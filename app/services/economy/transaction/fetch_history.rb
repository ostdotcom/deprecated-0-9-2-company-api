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
      # @param [Integer] page_no (optional) - page no
      # @param [Array] transaction_uuids (optional) - Array of transaction uuids
      #
      # @return [Economy::Transaction::FetchHistory]
      #
      def initialize(params)

        super

        @client_token_id = @params[:client_token_id]
        @page_no = @params[:page_no]

        @page_size = 25

        @client_token = nil
        @saas_api_response_data = nil
        @transaction_uuids = @params[:transaction_uuids] || []
      end

      # Perform
      #
      # * Author: Aman
      # * Date: 17/02/2018
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def perform

        r = validate_and_sanitize
        return r unless r.success?

        r = fetch_client_token
        return r unless r.success?

        # steps completed validations??

        # introduce has_more concept?
        #
        if @transaction_uuids.blank?
          r = fetch_transaction_uuids
          return r unless r.success?
        end

        return success_with_data({result_type: "transactions", transactions: [],
                                  meta: {next_page_payload: {}}}) if @transaction_uuids.blank?

        r = fetch_transaction_data_from_saas
        return r unless r.success?

        @saas_api_response_data[:meta] = {
            next_page_payload: {page_no: @page_no + 1}
        } if @transaction_uuids.count >= @page_size

        return success_with_data(@saas_api_response_data)

      end

      private

      # Validate and sanitize
      #
      # * Author: Puneet
      # * Date: 02/02/2018
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def validate_and_sanitize

        @page_no ||= 1

        @page_no = @page_no.to_i

        success

      end

      # Fetch Client token row
      # * Author: Aman
      # * Date: 17/02/2018
      # * Reviewed By:
      #
      # Sets @client_token
      #
      def fetch_client_token

        @client_token = CacheManagement::ClientToken.new([@client_token_id]).fetch[@client_token_id]

        return validation_error(
            'e_t_fh_2',
            'invalid_api_params',
            ['invalid_client_id'],
            GlobalConstant::ErrorAction.default
        ) if @client_token.blank?

        success

      end

      # Fetch paginated transaction uuids
      # * Author: Aman
      # * Date: 17/02/2018
      # * Reviewed By:
      #
      # Sets @transaction_uuids
      #
      def fetch_transaction_uuids

        offset = @page_size * (@page_no - 1)

        @transaction_uuids = ClientTokenTransaction.where(client_token_id: @client_token_id).limit(@page_size).
            offset(offset).order('id DESC').pluck(:transaction_uuid)

        success
      end

      # Fetch transaction data from saas using uuids
      #
      # * Author: Aman
      # * Date: 17/02/2018
      # * Reviewed By:
      #
      # Sets @saas_api_response_data
      #
      # @return [Result::Base]
      #
      def fetch_transaction_data_from_saas

        params = {
            client_id: @client_token[:client_id],
            token_symbol: @client_token[:symbol],
            transaction_uuids: @transaction_uuids
        }

        r = SaasApi::Transaction::FetchDetails.new.perform(params)
        return r unless r.success?

        @saas_api_response_data = r.data

        success
      end

    end

  end

end
