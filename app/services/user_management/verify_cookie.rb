module UserManagement

  class VerifyCookie < ServicesBase

    def initialize(params)
      super

      @cookie_value = @params[:cookie_value]
      @browser_user_agent = @params[:browser_user_agent]

      @user_id = nil
      @created_ts = nil
      @token = nil

      @user = nil
      @extended_cookie_value = nil
    end

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
          extended_cookie_value: @extended_cookie_value,
          client_id: @user.client_id
      )

    end

    private

    def set_parts
      parts = @cookie_value.split(':')
      return unauthorized_access_response('um_vc_1') unless parts.length == 3

      @user_id = parts[0].to_i
      return unauthorized_access_response('um_vc_2') unless @user_id > 0

      @created_ts = parts[1].to_i
      return unauthorized_access_response('um_vc_3') unless (@created_ts + GlobalConstant::Cookie.user_expiry.to_i) >= Time.now.to_i

      @token = parts[2]

      success
    end

    def validate_token
      @user = User.get_from_memcache(@user_id)
      return unauthorized_access_response('um_vc_4') unless @user.present? && @user.password.present? &&
          (@user[:status] == GlobalConstant::User.active_status)

      evaluated_token = User.get_cookie_token(@user_id, @user[:password], @browser_user_agent, @created_ts)
      return unauthorized_access_response('um_vc_5') unless (evaluated_token == @token)

      success
    end

    def set_extended_cookie_value
      #return if (@created_ts + 29.days.to_i) >= Time.now.to_i
      @extended_cookie_value = User.get_cookie_value(@user_id, @user[:password], @browser_user_agent)
    end


    def unauthorized_access_response(err, display_text = 'Unauthorized access. Please login again.')
      error_with_data(
          err,
          display_text,
          display_text,
          GlobalConstant::ErrorAction.default,
          {}
      )
    end

  end

end