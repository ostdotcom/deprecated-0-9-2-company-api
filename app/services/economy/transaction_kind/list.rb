module Economy

  module TransactionKind

    class List < Economy::TransactionKind::Base

      # Initialize
      #
      # * Author: Puneet
      # * Date: 29/01/2018
      # * Reviewed By:
      #
      # @params [String] client_id (mandatory) - client_id
      # @param [Integer] client_token_id (mandatory) - Client Token Id
      # @param [Integer] user_id (mandatory) - user Id
      # @param [Integer] is_xhr (mandatory) - is request xhr 0/1
      #
      # @return [Economy::TransactionKind::List]
      #
      def initialize(params)

        super

        @user_id = @params[:user_id]
        @client_token_id = @params[:client_token_id]
        @is_xhr = @params[:is_xhr]

        @api_response_data = {}

      end

      # Perform
      #
      # * Author: Puneet
      # * Date: 29/01/2018
      # * Reviewed By:
      #
      # Sets @api_response_data
      #
      # @return [Result::Base]
      #
      def perform

        r = validate
        return r unless r.success?

        r = fetch_client_token
        return r unless r.success?

        r = fetch_kinds
        return r unless r.success?

        r = fetch_supporting_data
        return r unless r.success?

        success_with_data(@api_response_data)

      end

      private

      # execute
      #
      # * Author: Puneet
      # * Date: 29/01/2018
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def fetch_kinds

        r = instantiate_ost_sdk
        return r unless r.success?

        if is_xhr_request?
          r = @ost_sdk_obj.list(@params.to_hash)
          return r unless r.success?

          @api_response_data = r.data

        else

          api_spec_service_response = @ost_spec_sdk_obj.create(api_spec_params)

          return error_with_data(
              'e_tk_l_fk_1',
              'something_sent_wrong',
              GlobalConstant::ErrorAction.default
          ) unless api_spec_service_response.success?

          api_spec_service_response.data[:request_uri].gsub!(GlobalConstant::SaasApi.base_url, GlobalConstant::SaasApi.display_only_base_url)

          @api_response_data[:api_console_data] = {
              transaction_kind: {
                  create: api_spec_service_response.data
              }
          }
        end

        success

      end

      def api_spec_params
        # NOTE: Values inside {{}} are strictly for FE use. DO NOT CHANGE THEM
        {
          name: '{{uri_encoded name}}',
          kind: '{{kind}}',
          currency: '{{currency}}',
          amount: '{{amount}}',
          commission_percent: '{{commission_percent}}',
          arbitrary_amount: '{{arbitrary_amount}}',
          arbitrary_commission: '{{arbitrary_commission}}'
        }
      end

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
            'cum_lu_4',
            'invalid_api_params',
            ['invalid_client_token_id'],
            GlobalConstant::ErrorAction.default
        ) if @client_token.blank?

        success

      end

      # fetch supporting data for pi responce
      #
      # * Author: Puneet
      # * Date: 29/01/2018
      # * Reviewed By:
      #
      # Sets @api_response_data
      #
      # @return [Result::Base]
      #
      def fetch_supporting_data

        unless is_xhr_request?
          r = Util::FetchEconomyCommonEntities.new(
              user_id: @user_id, client_token_id: @client_token_id, client_token: @client_token
          ).perform
          return r unless r.success?
          @api_response_data.merge!(r.data)
        end

        success

      end

      def is_xhr_request?
        @is_xhr.to_i == 1
      end

    end

  end

end