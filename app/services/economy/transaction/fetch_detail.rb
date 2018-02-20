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
                transaction_uuid: transaction_uuid,
                status: 'active',
                transaction_hash: "uussyyuuwww-#{Time.now.to_i}",
                created_at: '2018-02-15 08:05:11',
                from_user_id: 2,
                to_user_id: 1,
                transaction_type_id: 2,
                client_token_id: 1,
                currency_value: 30,
                gas_value: 0.021,
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
                transaction_uuid: transaction_uuid,
                status: 'pending',
                transaction_hash: nil,
                created_at: nil,
                from_user_id: 3,
                to_user_id: 2,
                transaction_type_id: 3,
                currency_value: nil,
                gas_value: 0.001,
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
                    conversion_rate: 3.003,
                    setup_steps: [
                        "set_conversion_rate",
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
                    currency_type: "bt",
                    currency_value: "10",
                    commission_percent: "0.000",
                    status: "active"
                },
                2 => {
                    id: 2,
                    name: "Service Charge",
                    kind: "user_to_company",
                    currency_type: "bt",
                    currency_value: "30",
                    commission_percent: "0.000",
                    status: "active"
                },
                3 => {
                    id: 3,
                    name: "Like",
                    kind: "user_to_user",
                    currency_type: "usd",
                    currency_value: "20",
                    commission_percent: "10.000",
                    status: "active"
                },
            },

            result_type: "transactions",

            transactions: transactions,
            oracle_price_points: {
                ost: {
                    usd: 0.3
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
