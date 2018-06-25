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
        return validation_error(
            'e_sd_1',
            'invalid_api_params',
            ['invalid_client_token_id'],
            GlobalConstant::ErrorAction.default
        ) if @client_token.blank?

        return error_with_go_to(
            'e_sd_2',
            'token_setup_not_complete',
            GlobalConstant::GoTo.economy_planner_step_one
        ) if @client_token[:setup_steps].exclude?(GlobalConstant::ClientToken.setup_complete_step)

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
        return validation_error(
            'e_fss_2',
            'invalid_api_params',
            ['invalid_client_id'],
            GlobalConstant::ErrorAction.default
        ) if result.blank?

        # Create OST Sdk Obj
        ost_sdk = OSTSdk::Saas::Services.new(
            api_key: result[:api_key],
            api_secret: result[:api_secret],
            api_base_url: GlobalConstant::SaasApi.v1dot1_base_url,
            api_spec: true
        )
        @ost_spec_sdk_obj = ost_sdk.services.transactions

        api_spec_service_response = @ost_spec_sdk_obj.execute(api_spec_params)

        return api_spec_service_response unless api_spec_service_response.success?

        api_spec_service_response.data[:request_uri].gsub!(GlobalConstant::SaasApi.base_url, GlobalConstant::SaasApi.display_only_base_url)

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
          from_user_id: '{{from_user_id}}',
          to_user_id: '{{to_user_id}}',
          action_id: '{{action_id}}',
          amount: '{{amount}}',
          commission_percent: '{{commission_percent}}'
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
