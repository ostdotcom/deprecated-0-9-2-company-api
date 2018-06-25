module ClientUsersManagement

  class ListUser < ServicesBase

    # Initialize
    #
    # * Author: Puneet
    # * Date: 02/02/2018
    # * Reviewed By:
    #
    # @param [Integer] user_id (mandatory) - user Id
    # @param [Integer] client_id (mandatory) - Client Id
    # @param [Integer] client_token_id (mandatory) - Client Token Id
    # @param [Integer] is_xhr (mandatory) - is request xhr 0/1
    # @param [Integer] page_no (optional) - page no
    # @param [String] order_by (optional) - creation_time
    # @param [String] order (optional) - Order type('asc', 'desc')
    # @param [String] airdropped (optional) - true / false for filtering
    #
    # @return [ClientUsersManagement::ListUser]
    #
    def initialize(params)

      super

      @client_id = @params[:client_id]
      @client_token_id = @params[:client_token_id]
      @user_id = @params[:user_id]
      @page_no = @params[:page_no]
      @order_by = @params[:order_by]
      @order = @params[:order]
      @is_xhr = @params[:is_xhr]
      @airdropped = @params[:airdropped]

      @page_size = 25
      @client = nil
      @api_response_data = {}

    end

    # Perform
    #
    # * Author: Puneet
    # * Date: 02/02/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def perform

      r = validate_and_sanitize
      return r unless r.success?

      r = fetch_client_token
      return r unless r.success?

      r = fetch_users
      return r unless r.success?

      return api_response

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

      r = validate
      return r unless r.success?

      r = validate_client
      return r unless r.success?

      success

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
      return error_with_data(
          'cum_lu_4',
          'something_went_wrong',
          GlobalConstant::ErrorAction.default
      ) if @client_token.blank?

      return error_with_go_to(
          'cum_lu_5',
          'token_setup_not_complete',
          GlobalConstant::GoTo.economy_planner_step_one
      ) if @client_token[:setup_steps].exclude?(GlobalConstant::ClientToken.setup_complete_step)

      success

    end

    # Validate Input client
    #
    # * Author: Puneet
    # * Date: 02/02/2018
    # * Reviewed By:
    #
    # Sets @client
    #
    # @return [Result::Base]
    #
    def validate_client

      @client = CacheManagement::Client.new([@client_id]).fetch[@client_id]

      return validation_error(
          'cum_lu_3',
          'invalid_api_params',
          ['invalid_client_id'],
          GlobalConstant::ErrorAction.mandatory_params_missing
      ) if @client.blank? || @client[:status] != GlobalConstant::Client.active_status

      @client_id = @client_id.to_i

      success

    end

    # Fetch users
    #
    # * Author: Puneet
    # * Date: 02/02/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def fetch_users

      result = CacheManagement::ClientApiCredentials.new([@client_id]).fetch[@client_id]
      return validation_error(
          'cum_lu_6',
          'invalid_api_params',
          ['invalid_client_id'],
          GlobalConstant::ErrorAction.default
      ) if result.blank?

      if is_xhr_request?

        ost_sdk = OSTSdk::Saas::Services.new(
            api_key: result[:api_key],
            api_secret: result[:api_secret],
            api_base_url: GlobalConstant::SaasApi.v1dot1_base_url,
            api_spec: false
        )

        @ost_sdk_obj = ost_sdk.services.users

        list_params = {}
        list_params[:page_no] = @page_no unless @page_no.nil?
        list_params[:order_by] = @order_by unless @page_no.nil?
        list_params[:order] = @order unless @page_no.nil?
        list_params[:airdropped] = @airdropped unless @airdropped.nil?

        service_response = @ost_sdk_obj.list(list_params)

        return service_response unless service_response.success?

        @api_response_data = service_response.data

      else

        ost_sdk = OSTSdk::Saas::Services.new(
            api_key: result[:api_key],
            api_secret: result[:api_secret],
            api_base_url: GlobalConstant::SaasApi.v1dot1_base_url,
            api_spec: true
        )

        @ost_spec_sdk_obj = ost_sdk.services.users
        api_spec_service_response = @ost_spec_sdk_obj.create({name: "{{uri_encoded name}}"})

        return api_spec_service_response unless api_spec_service_response.success?

        api_spec_service_response.data[:request_uri].gsub!(GlobalConstant::SaasApi.base_url, GlobalConstant::SaasApi.display_only_base_url)

        @api_response_data[:api_console_data] = {
            user: {
                create: api_spec_service_response.data
            }
        }

      end

      success

    end

    # API response
    #
    # * Author: Puneet
    # * Date: 02/02/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def api_response

      unless is_xhr_request?
        r = Util::FetchEconomyCommonEntities.new(
            user_id: @user_id, client_token_id: @client_token_id, client_token: @client_token
        ).perform
        return r unless r.success?
        @api_response_data.merge!(r.data)
      end

      success_with_data(@api_response_data)

    end

    def creation_time_order_by
      'creation_time'
    end

    def is_xhr_request?
      @is_xhr.to_i == 1
    end

  end

end
