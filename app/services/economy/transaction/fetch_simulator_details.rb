module Economy

  module Transaction

    class FetchSimulatorDetails < ServicesBase

      # Initialize
      #
      # * Author: Puneet
      # * Date: 31/01/2018
      # * Reviewed By:
      #
      # @params [Integer] client_id (mandatory) - client id
      # @params [Integer] client_token_id (mandatory) - client token id
      # @params [Integer] user_id (mandatory) - user id
      #
      # @return [Economy::FetchSimulatorDetails]
      #
      def initialize(params)

        super

        @client_token_id = @params[:client_token_id]
        @client_id = @params[:client_id]
        @user_id = @params[:user_id]

        @client_token = nil
        @api_response_data = {}

      end

      # Perform
      #
      # * Author: Puneet
      # * Date: 31/01/2018
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def perform

        r = validate
        return r unless r.success?

        r = fetch_client_token
        return r unless r.success?

        r = fetch_api_console_data
        return r unless r.success?

        r = fetch_common_entities
        return r unless r.success?

        success_with_data(@api_response_data)

      end

      private

      #
      # * Author: Puneet
      # * Date: 31/01/2018
      # * Reviewed By:
      #
      # Sets @client_token
      #
      def fetch_client_token

        @client_token = CacheManagement::ClientToken.new([@client_token_id]).fetch[@client_token_id]
        return error_with_data(
            'e_sd_1',
            'Token not found.',
            'Token not found.',
            GlobalConstant::ErrorAction.default,
            {}
        ) if @client_token.blank?

        return error_with_go_to(
            'e_sd_2',
            'Token SetUp Not Complete.',
            'Token SetUp Not Complete.',
            GlobalConstant::GoTo.economy_planner_step_one
        ) if @client_token[:setup_steps].exclude?(GlobalConstant::ClientToken.airdrop_done_setup_step)

        success

      end

      # Fetch Api console data for Transaction kind create
      #
      # * Author: Puneet
      # * Date: 3/03/2018
      # * Reviewed By:
      #
      # Sets @api_response_data
      #
      # @return [Result::Base]
      #
      def fetch_api_console_data

        result = CacheManagement::ClientApiCredentials.new([@client_id]).fetch[@client_id]
        return error_with_data(
            'e_gtss_2',
            "Invalid client",
            'Something Went Wrong.',
            GlobalConstant::ErrorAction.default,
            {}
        ) if result.blank?

        # Create OST Sdk Obj
        credentials = OSTSdk::Util::APICredentials.new(result[:api_key], result[:api_secret])
        @ost_spec_sdk_obj = OSTSdk::Saas::TransactionKind.new(GlobalConstant::Base.sub_env, credentials, true)

        api_spec_service_response = @ost_spec_sdk_obj.transfer_bt_by_transaction_kind(api_spec_params)

        return error_with_data(
            'e_gtss_3',
            "Coundn't fetch api spec for transaction execute",
            'Something Went Wrong.',
            GlobalConstant::ErrorAction.default,
            {}
        ) unless api_spec_service_response.success?

        @api_response_data[:api_console_data] = {
            transaction: {
                execute: api_spec_service_response.data
            }
        }

        success

      end

      def api_spec_params
        # NOTE: Values inside {{}} are strictly for FE use. DO NOT CHANGE THEM
        {
          token_symbol: '{{bt_symbol}}',
          from_uuid: '{{from_user_id}}',
          to_uuid: '{{to_user_id}}',
          transaction_kind: '{{transaction_kind}}'
        }
      end

      #
      # * Author: Puneet
      # * Date: 31/01/2018
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def fetch_common_entities

        r = Util::FetchEconomyCommonEntities.new(
            user_id: @user_id,
            client_token_id: @client_token_id,
            client_token: @client_token
        ).perform
        return r unless r.success?

        @api_response_data.merge!(r.data)

        success

      end

    end

  end

end
