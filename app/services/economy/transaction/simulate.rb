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

        dummy_response = {

            economy_users: {
                2 => {
                    id: 2,
                    name: "Aman User1",
                    uuid: "a2",
                    total_airdropped_tokens: "active",
                    token_balance: 100
                },
                3 => {
                    id: 3,
                    name: "Rachin User3",
                    uuid: "a3",
                    total_airdropped_tokens: "active",
                    token_balance: 10
                }

            },

            client_tokens: {
                1 => {
                    id: 1,
                    client_id: 1,
                    name: "TakTakTak",
                    symbol: "T3K",
                    symbol_icon: '',
                    status: "active",
                    conversion_factor: 3.003,
                    setup_steps: [
                        "token_worth_in_usd",
                        "configure_transactions",
                        "propose_initiated",
                        "propose_done",
                        "registered_on_uc",
                        "registered_on_vc",
                        "received_test_ost"
                    ]
                }

            },

            transaction_types: {
                1 => {
                    id: 1,
                    name: "Upvote",
                    kind: "user_to_user",
                    currency_type: "BT",
                    currency_value: "10",
                    commission_percent: "0.000",
                    status: "active"
                }
            },

            result_type: "transactions",

            transactions: [
                {   id: "a2-a3-#{Time.now.to_i}",
                    transaction_uuid: "a2-a3-#{Time.now.to_i}",
                    status: 'pending',
                    transaction_hash: nil,
                    uts: "#{Time.now.to_i}",
                    from_user_id: 2,
                    to_user_id: 3,
                    transaction_type_id: 1,
                    client_token_id: 1,
                    currency_value: 10,
                    gas_value: nil,
                    block_number: nil,
                    block_timestamp: nil,
                    transfers: [
                        {
                            from_user_id: 2,
                            to_user_id: 3,
                            type: 'transfer',
                            currency_value: 10
                        }
                    ]
                }
            ],
            oracle_price_points: {
                OST: {
                    USD: 0.3
                }
            },
            meta: {
                next_page_payload: {

                }
            }

        }


        return success_with_data(dummy_response)


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

        params = {
            token_symbol: @client_token[:symbol]
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
        ) if @saas_api_response_data[:result].length != 1

        return error_with_data(
            'e_t_s_3',
            'Invalid Response from Saas',
            'Something Went Wrong',
            GlobalConstant::ErrorAction.default,
            {}
        ) if @saas_api_response_data[:result][0][:type] != GlobalConstant::SaasApiEntityType.result_transaction_type

        id = @saas_api_response_data[:result][0][:id]
        transaction = @saas_api_response_data[GlobalConstant::SaasApiEntityType.transaction_entity_key][id]

        @transaction_uuid = transaction[:uuid]

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
        @api_response_data = @saas_api_response_data
      end

    end

  end

end
