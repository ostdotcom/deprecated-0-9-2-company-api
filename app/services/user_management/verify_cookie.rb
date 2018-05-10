module UserManagement

  class VerifyCookie < ServicesBase

    # Initialize
    #
    # * Author: Alpesh
    # * Date: 15/01/2018
    # * Reviewed By:
    #
    # @param [String] cookie_value (mandatory) - cookie value
    # @params [String] browser_user_agent (mandatory) - browser user agent
    #
    # @return [UserManagement::VerifyCookie]
    #
    def initialize(params)
      super

      @cookie_value = @params[:cookie_value]
      @browser_user_agent = @params[:browser_user_agent]

      @user_id = nil
      @client_id = nil
      @created_ts = nil
      @token = nil

      @user = nil
      @client = nil
      @extended_cookie_value = nil

    end

    # Perform
    #
    # * Author: Alpesh
    # * Date: 15/01/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def perform

      r = validate
      return r unless r.success?

      r = set_parts
      return r unless r.success?

      r = validate_token
      return r unless r.success?

      set_extended_cookie_value

      success_with_data(
          user_id: @user_id,
          client_id: @client_id,
          client_token_id: @client[:default_token_id],
          extended_cookie_value: @extended_cookie_value
      )

    end

    private

    # Set Parts
    #
    # * Author: Alpesh
    # * Date: 15/01/2018
    # * Reviewed By:
    #
    # Sets @user_id, @client_id, @created_ts, @token
    #
    # @return [Result::Base]
    #
    def set_parts
      parts = @cookie_value.split(':')
      return unauthorized_access_response('um_vc_1') unless parts.length == 4

      @user_id = parts[0].to_i
      return unauthorized_access_response('um_vc_2') unless @user_id > 0

      @client_id = parts[1].to_i
      return unauthorized_access_response('um_vc_3') unless @client_id >= 0

      @created_ts = parts[2].to_i
      return unauthorized_access_response('um_vc_4') unless (@created_ts + GlobalConstant::Cookie.user_expiry.to_i) >= Time.now.to_i

      @token = parts[3]

      success
    end

    # Validate token
    #
    # * Author: Alpesh
    # * Date: 15/01/2018
    # * Reviewed By:
    #
    # Sets @user, @user_s, @client
    #
    # @return [Result::Base]
    #
    def validate_token

      @user = CacheManagement::User.new([@user_id]).fetch[@user_id]

      return unauthorized_access_response('um_vc_5') unless @user.present? &&
          @user[:status] == GlobalConstant::User.active_status

      @user_s = CacheManagement::UserSecure.new([@user_id]).fetch[@user_id]

      evaluated_token = User.get_cookie_token(@user_id, @client_id, @user_s[:password], @browser_user_agent, @created_ts)
      return unauthorized_access_response('um_vc_7') unless (evaluated_token == @token)

      @client = CacheManagement::Client.new([@client_id]).fetch[@client_id]

      # if @client_id != default_client_id
      # check for client id to be existing in client managers table
      if @client_id != @user[:default_client_id]
        return unauthorized_access_response('um_vc_6') if @client[:manager_user_ids].exclude?(@user_id)
      end

      success

    end

    # Set extended cookie value
    #
    # * Author: Alpesh
    # * Date: 15/01/2018
    # * Reviewed By:
    #
    # Sets @extended_cookie_value
    #
    def set_extended_cookie_value
      #return if (@created_ts + 29.days.to_i) >= Time.now.to_i
      @extended_cookie_value = User.get_cookie_value(@user_id, @client_id, @user_s[:password], @browser_user_agent)
    end

    # Unauthorized access response
    #
    # * Author: Alpesh
    # * Date: 15/01/2018
    # * Reviewed By:
    #
    # @param [String] err (mandatory) - err code
    # @param [String] display_text (optional) - display text
    #
    # @return [Result::Base]
    #
    def unauthorized_access_response(err)
      error_with_data(
          err,
          'unauthorized_access_response',
          GlobalConstant::ErrorAction.default
      )
    end

  end

end