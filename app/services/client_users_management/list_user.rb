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
    # @param [String] filter (optional) - filter on user list type
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
      @filter = @params[:filter]

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

      r = validate_pagination_params
      return r unless r.success?

      r = validate_client
      return r unless r.success?

      success

    end

    # Validate pagination params
    #
    # * Author: Puneet
    # * Date: 02/02/2018
    # * Reviewed By:
    #
    # Sets @client
    #
    # @return [Result::Base]
    #
    def validate_pagination_params

      if @page_no.present?
        return error_with_data(
            'cum_lu_1',
            "Invalid Page No.",
            "Invalid Page No.",
            GlobalConstant::ErrorAction.mandatory_params_missing,
            {}
        ) unless Util::CommonValidator.is_numeric?(@page_no)
        @page_no = @page_no.to_i
      else
        @page_no = 1
      end

      if @order_by.present?
        return error_with_data(
            'cum_lu_vpp_1',
            "Invalid @order_by",
            "Invalid @order_by",
            GlobalConstant::ErrorAction.mandatory_params_missing,
            {}
        ) if [creation_time_order_by].exclude?(@order_by)
      else
        @order_by = ''
      end

      if @order.present?
        return error_with_data(
            'cum_lu_vpp_2',
            "Invalid @order",
            "Invalid @order",
            GlobalConstant::ErrorAction.mandatory_params_missing,
            {}
        ) if ['asc', 'desc'].exclude?(@order.downcase)
      else
        @order = ''
      end

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

      return error_with_data(
          'cum_lu_2',
          "Invalid client.",
          'Something Went Wrong.',
          GlobalConstant::ErrorAction.mandatory_params_missing,
          {}
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
      return error_with_data(
          'uc_lu_1',
          "Invalid client.",
          'Something Went Wrong.',
          GlobalConstant::ErrorAction.default,
          {}
      ) if result.blank?

      # Create OST Sdk Obj
      credentials = OSTSdk::Util::APICredentials.new(result[:api_key], result[:api_secret])

      if is_xhr_request?

        @ost_sdk_obj = OSTSdk::Saas::Users.new(GlobalConstant::Base.sub_env, credentials)

        service_response = @ost_sdk_obj.list(page_no: @page_no, order_by: @order_by, order: @order, filter: @filter)

        return error_with_data(
            'uc_lu_2',
            "Coundn't Fetch User List",
            'Something Went Wrong.',
            GlobalConstant::ErrorAction.default,
            {}
        ) unless service_response.success?

        @api_response_data = service_response.data
      else

        @ost_spec_sdk_obj = OSTSdk::Saas::Users.new(GlobalConstant::Base.sub_env, credentials, true)
        api_spec_service_response = @ost_spec_sdk_obj.create({name: "{{uri_encoded name}}"})

        return error_with_data(
            'cum_lu_fu_1',
            "Coundn't Fetch Api spec for user create",
            'Something Went Wrong.',
            GlobalConstant::ErrorAction.default,
            {}
        ) unless api_spec_service_response.success?

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
        r = Util::FetchEconomyCommonEntities.new(user_id: @user_id, client_token_id: @client_token_id).perform
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
