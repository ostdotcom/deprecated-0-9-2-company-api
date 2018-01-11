module UserManagement

  class Login < ServicesBase

    def initialize(params)
      super

      @email = @params[:email]
      @password = @params[:password]
      @browser_user_agent = @params[:browser_user_agent]
      @ip_address = @params[:ip_address]

      @user_secret = nil
      @user = nil
      @login_salt_d = nil
    end

    def perform

      r = validate
      return r unless r.success?

      r = fetch_user
      return r unless r.success?

      r = decrypt_login_salt
      return r unless r.success?

      r = validate_password
      return r unless r.success?

      enqueue_job

      set_cookie_value

    end

    private

    def fetch_user
      @user = User.where(email: @email).first
      return unauthorized_access_response('um_l_1') unless @user.present? && @user.password.present? &&
          (@user.status == GlobalConstant::User.active_status)

      return error_with_data(
          'um_l_4',
          'The token sale ended, this account was not activated during the sale.',
          'The token sale ended, this account was not activated during the sale.',
          GlobalConstant::ErrorAction.default,
          {},
          {}
      ) if GlobalConstant::TokenSale.is_general_sale_ended? && !@user.send("#{GlobalConstant::User.token_sale_double_optin_done_property}?")



      @user_secret = UserSecret.where(id: @user.user_secret_id).first
      return unauthorized_access_response('um_l_2') unless @user_secret.present?

      success
    end

    def decrypt_login_salt
      r = Aws::Kms.new('login','user').decrypt(@user_secret.login_salt)
      return r unless r.success?

      @login_salt_d = r.data[:plaintext]

      success
    end

    def validate_password

      evaluated_password_e = User.get_encrypted_password(@password, @login_salt_d)
      return unauthorized_access_response('um_l_3') unless (evaluated_password_e == @user.password)

      success
    end

    def enqueue_job
      BgJob.enqueue(
          UserActivityLogJob,
          {
              user_id: @user.id,
              action:   GlobalConstant::UserActivityLog.login_action,
              action_timestamp: Time.now.to_i,
              extra_data: {
                  browser_user_agent: @browser_user_agent,
                  ip_address: @ip_address
              }

          }
      )
    end

    def set_cookie_value
      cookie_value = User.get_cookie_value(@user.id, @user.password, @browser_user_agent)

      success_with_data(cookie_value: cookie_value, user_token_sale_state: @user.get_token_sale_state_page_name)
    end

    def unauthorized_access_response(err, display_text = 'Incorrect login details.')
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