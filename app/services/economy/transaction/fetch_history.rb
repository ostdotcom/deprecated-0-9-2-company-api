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
      #
      # @return [Economy::Transaction::FetchHistory]
      #
      def initialize(params)

        super

        @client_token_id = @params[:client_token_id]
        @page_no = @params[:page_no]

        @page_size = 10

        @client_token = nil
        @saas_api_response_data = nil
        @transaction_uuids = []
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

            transactions: [
                {
                    id: 'a2-a3',
                    transaction_uuid: 'a2-a3',
                    status: 'active',
                    transaction_hash: "uussyyuuwww-#{Time.now.to_i}",
                    uts: "#{Time.now.to_i}",
                    from_user_id: 2,
                    to_user_id: 3,
                    transaction_type_id: 1,
                    client_token_id: 1,
                    currency_value: 10,
                    gas_value: 0.011,
                    block_number: 1,
                    block_timestamp: "#{Time.now.to_i}",
                    transfers: [
                        {
                            from_user_id: 2,
                            to_user_id: 3,
                            type: 'transfer',
                            currency_value: 10
                        }
                    ]
                },
                {
                    id: 'a2-a1',
                    transaction_uuid: 'a2-a1',
                    status: 'active',
                    transaction_hash: "uussyyuuwww-#{Time.now.to_i}",
                    uts: "#{Time.now.to_i}",
                    from_user_id: 2,
                    to_user_id: 1,
                    transaction_type_id: 2,
                    client_token_id: 1,
                    currency_value: 30,
                    gas_value: 0.021,
                    block_number: 2,
                    block_timestamp: "#{Time.now.to_i}",
                    transfers: [
                        {
                            from_user_id: 2,
                            to_user_id: 1,
                            type: 'transfer',
                            currency_value: 30
                        }
                    ]
                },
                {
                    id: 'a3-a2',
                    transaction_uuid: 'a3-a2',
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
            ],
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


        r = validate_and_sanitize
        return r unless r.success?

        r = fetch_client_token
        return r unless r.success?

        # steps completed validations??

        # introduce has_more concept?
        #
        r = fetch_transaction_uuids
        return r unless r.success?

        return success if @transaction_uuids.blank?

        r = fetch_transaction_data_from_saas
        return r unless r.success?

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
        if @page_no.present?
          return error_with_data(
              'e_t_fh_1',
              "Invalid Page No.",
              "Invalid Page No.",
              GlobalConstant::ErrorAction.mandatory_params_missing,
              {}
          ) unless Util::CommonValidator.is_numeric?(@page_no)
          @page_no = @page_no.to_i
        else
          @page_no = 1
        end

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
        return error_with_data(
            'e_t_fh_2',
            'Token not found.',
            'Token not found.',
            GlobalConstant::ErrorAction.default,
            {}
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
            offset(offset).sort(id: :desc).pluck(:transaction_uuid)

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
