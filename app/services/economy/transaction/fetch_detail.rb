module Economy

  module Transaction

    class FetchDetail < ServicesBase

      # Initialize
      #
      # * Author: Puneet
      # * Date: 02/02/2018
      # * Reviewed By:
      #
      # @params [Integer] client_token_id (mandatory) - client token id
      # @param [Array] transaction_uuids (optional) - transaction uuids
      #
      # @return [Economy::Transaction::FetchDetail]
      #
      def initialize(params)

        super

        @client_token_id = @params[:client_token_id]
        @transaction_uuids = @params[:transaction_uuids]

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

        transactions = []

        @transaction_uuids.each do |transaction_uuid|

          if (Time.now.to_i % 2 == 0)
            data = {
                id: transaction_uuid,
                transaction_uuid: transaction_uuid,
                uts: "#{Time.now.to_i}",
                from_user_id: 2,
                to_user_id: 1,
                transaction_type_id: 2,
                client_token_id: 1,
                currency_value: 30,
                gas_value: 0.021,
                status: 'active',
                transaction_hash: "uussyyuuwww-#{Time.now.to_i}",
                block_number: 3,
                block_timestamp: "#{Time.now.to_i}",
                transfers: [
                    {
                        from_user_id: 2,
                        to_user_id: 1,
                        type: 'transfer',
                        currency_value: 30
                    }
                ]
            }
          else
            data = {
                id: transaction_uuid,
                transaction_uuid: transaction_uuid,
                status: 'pending',
                transaction_hash: nil,
                uts: "#{Time.now.to_i}",
                from_user_id: 3,
                to_user_id: 2,
                transaction_type_id: 3,
                currency_value: nil,
                gas_value: nil,
                block_number: nil,
                block_timestamp: nil,
                transfers: []
            }
          end

          transactions << data

        end


        dummy_response = {

            economy_users: {
                1 => {
                    id: 1,
                    name: "company User",
                    uuid: "a1",
                    total_airdropped_tokens: "active",
                    token_balance: 1000
                },
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
                },
                2 => {
                    id: 2,
                    name: "Service Charge",
                    kind: "user_to_company",
                    currency_type: "BT",
                    currency_value: "30",
                    commission_percent: "0.000",
                    status: "active"
                },
                3 => {
                    id: 3,
                    name: "Like",
                    kind: "user_to_user",
                    currency_type: "USD",
                    currency_value: "20",
                    commission_percent: "10.000",
                    status: "active"
                },
            },

            result_type: "transactions",

            transactions: transactions,
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

      end

    end

  end

end
