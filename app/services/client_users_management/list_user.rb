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
    # @param [Integer] page_no (optional) - page no
    # @param [String] order_by (optional) - creation_time
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
            'cum_lu_1',
            "Invalid @order_by",
            "Invalid @order_by",
            GlobalConstant::ErrorAction.mandatory_params_missing,
            {}
        ) if [creation_time_order_by].exclude?(@order_by)
      else
        @order_by = ''
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
      render_api_response(
          error_with_data(
              'uc_lu_1',
              "Invalid client.",
              'Something Went Wrong.',
              GlobalConstant::ErrorAction.default,
              {}
          )
      ) if result.blank?

      # Create OST Sdk Obj
      credentials = OSTSdk::Util::APICredentials.new(result[:api_key], result[:api_secret])
      @ost_sdk_obj = OSTSdk::Saas::Users.new(GlobalConstant::Base.sub_env, credentials)

      service_response = @ost_sdk_obj.list(page_no: @page_no, sort_by: @order_by)

      @api_response_data = service_response.data

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

      if @page_no == 1
        r = Util::FetchEconomyCommonEntities.new(user_id: @user_id, client_token_id: @client_token_id).perform
        return r unless r.success?
        @api_response_data.merge!(r.data)
      end

      success_with_data(@api_response_data)

    end

    def creation_time_order_by
      'creation_time'
    end

  end

end
