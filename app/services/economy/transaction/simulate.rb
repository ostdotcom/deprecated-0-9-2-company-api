module Economy

  module Transaction

    class Simulate < ServicesBase

      # Initialize
      #
      # * Author: Puneet
      # * Date: 02/02/2018
      # * Reviewed By:
      #
      # @params [Integer] client_token_id (mandatory) - client token id
      #
      # @return [Economy::Transaction::Simulate]
      #
      def initialize(params)

        super

        @client_token_id = @params[:client_token_id]

        @client_token = nil
        @saas_api_response_data = nil
        @transaction_uuid = nil
        @api_response_data = nil
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

        r = validate
        return r unless r.success?

        r = fetch_client_token
        return r unless r.success?


        # steps completed validations??

        r = simulate_transaction
        return r unless r.success?

        r = parse_saas_response
        return r unless r.success?

        create_client_token_transaction

        set_api_response_data

        return success_with_data(@api_response_data)

      end


      private

      #
      # * Author: Aman
      # * Date: 17/02/2018
      # * Reviewed By:
      #
      # Sets @client_token
      #
      def fetch_client_token

        @client_token = CacheManagement::ClientToken.new([@client_token_id]).fetch[@client_token_id]
        return error_with_data(
            'e_t_s_1',
            'Token not found.',
            'Token not found.',
            GlobalConstant::ErrorAction.default,
            {}
        ) if @client_token.blank?

        success

      end

      # Propose
      #
      # * Author: Aman
      # * Date: 17/02/2018
      # * Reviewed By:
      #
      # Sets @saas_api_response_data
      #
      # @return [Result::Base]
      #
      def simulate_transaction

        prioritize_tx_flags = CacheManagement::ClientPrioritizeTxFlag.new([@client_token_id]).fetch[@client_token_id]

        params = {
          token_symbol: @client_token[:symbol],
          client_id: @client_token[:client_id],
          prioritize_company_txs: prioritize_tx_flags[:company_to_user]
        }

        r = SaasApi::Transaction::Simulate.new.perform(params)
        return r unless r.success?

        @saas_api_response_data = r.data

        success

      end


      # Parse data received from saas
      #
      # * Author: Aman
      # * Date: 17/02/2018
      # * Reviewed By:
      #
      # Sets @transaction_uuid
      #
      # @return [Result::Base]
      #
      def parse_saas_response

        return error_with_data(
            'e_t_s_2',
            'Invalid Response from Saas',
            'Something Went Wrong',
            GlobalConstant::ErrorAction.default,
            {}
        ) if @saas_api_response_data.blank?

        @transaction_uuid = @saas_api_response_data[:transaction_uuid]

        return error_with_data(
            'e_t_s_4',
            'Invalid Response from Saas',
            'Transaction could not be stimulated',
            GlobalConstant::ErrorAction.default,
            {}
        ) if @transaction_uuid.blank?

        success
      end


      # create client token transaction
      #
      # * Author: Aman
      # * Date: 17/02/2018
      # * Reviewed By:
      #
      # Sets @client_token_transaction
      #
      # @return [Result::Base]
      #
      def create_client_token_transaction

        ClientTokenTransaction.create!(
            {
                client_token_id: @client_token_id,
                transaction_uuid: @transaction_uuid

            }
        )
      end

      # Set response data
      #
      # * Author: Aman
      # * Date: 17/02/2018
      # * Reviewed By:
      #
      # Sets @api_response_data
      # ``
      def set_api_response_data
        service_response = Economy::Transaction::FetchHistory.new({transaction_uuids: [@transaction_uuid],
                                                                   client_token_id: @client_token_id}).perform
        @api_response_data = service_response.data
      end

    end

  end

end
