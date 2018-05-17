module Economy

  module TokenSetupDetails

    class StepTwo < Economy::TokenSetupDetails::Base

      # Initialize
      #
      # * Author: Puneet
      # * Date: 31/01/2018
      # * Reviewed By:
      #
      # @params [Integer] client_token_id (mandatory) - client token id
      # @params [Integer] user_id (mandatory) - user id
      #
      # @return [Economy::TokenSetupDetails::StepTwo]
      #
      def initialize(params)
        super

        @ost_spec_sdk_obj = nil
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
        r = super
        return r unless r.success?

        r = fetch_api_console_data
        return r unless r.success?

        success_with_data(@api_response_data)
      end

      private

      # Verify if client can view this page
      # If not set appropriate error go to
      #
      # * Author: Puneet
      # * Date: 31/01/2018
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def validate_step

        return error_with_go_to(
            'e_tss_st_1',
            'token_setup_not_complete',
            GlobalConstant::GoTo.economy_planner_step_one
        ) unless is_client_step_one_complete?

        r = fetch_eth_ost_balance(true)
        return r unless r.success?

        if @api_response_data[:client_balances].blank? ||
            @api_response_data[:client_balances][GlobalConstant::BalanceTypes.ost_balance_type].blank?

          return error_with_go_to(
              'e_tss_st_3',
              'token_setup_not_complete',
              GlobalConstant::GoTo.economy_planner_step_one
          ) unless r.success?

        end

        r = super
        return r unless r.success?

        success

      end

      # Sub classes to fetch required data
      #
      # * Author: Puneet
      # * Date: 31/01/2018
      # * Reviewed By:
      #
      # Sets @api_response_data
      #
      # @return [Result::Base]
      #
      def fetch_setup_details

        r = super
        return r unless r.success?

        r = SaasApi::Client::FetchStats.new.perform(client_id: @client_id)
        @api_response_data[:client_stats] = r.data if r.success?

        success

      end


      # Fetch Api console data for Transaction kind create
      #
      # * Author: Aman
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
            'e_tss_tw_2',
            'invalid_api_params',
            ['invalid_client_id'],
            GlobalConstant::ErrorAction.default
        )  if result.blank?

        # Create OST Sdk Obj
        ost_sdk = OSTSdk::Saas::Services.new(
            api_key: result[:api_key],
            api_secret: result[:api_secret],
            api_base_url: "#{GlobalConstant::SaasApi.base_url}v1",
            api_spec: true
        )

        @ost_spec_sdk_obj = ost_sdk.services.actions

        api_spec_service_response = @ost_spec_sdk_obj.create(api_spec_params)

        return api_spec_service_response unless api_spec_service_response.success?

        api_spec_service_response.data[:request_uri].gsub!(GlobalConstant::SaasApi.base_url, GlobalConstant::SaasApi.display_only_base_url)

        @api_response_data[:api_console_data] = {
            transaction_kind: {
                create: api_spec_service_response.data
            }
        }

        success
      end

      def api_spec_params
        # NOTE: Values inside {{}} are strictly for FE use. DO NOT CHANGE THEM
        {
            name: '{{uri_encoded name}}',
            kind: '{{kind}}',
            currency_type: '{{currency_type}}',
            currency_value: '{{currency_value}}',
            commission_percent: '{{commission_percent}}'
        }
      end

    end

  end

end
