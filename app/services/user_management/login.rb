module UserManagement

  class Login < ServicesBase

    # Initialize
    #
    # * Author: Alpesh
    # * Date: 15/01/2018
    # * Reviewed By:
    #
    # @param [String] email (mandatory) - the email of the user which is to be signed up
    # @param [String] password (mandatory) - user password
    # @params [String] browser_user_agent (mandatory) - browser user agent
    #
    # @return [UserManagement::Login]
    #
    def initialize(params)
      super

      @email = @params[:email]
      @password = @params[:password]
      @browser_user_agent = @params[:browser_user_agent]

      @user = nil
      @login_salt_d = nil
      @logged_in_at = Time.now.to_i
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

      r = fetch_user
      return r unless r.success?

      r = decrypt_login_salt
      return r unless r.success?

      r = validate_password
      return r unless r.success?

      r = mark_user_logged_in
      return r unless r.success?

      set_cookie_value

    end

    private

    # Fetch user
    #
    # * Author: Alpesh
    # * Date: 15/01/2018
    # * Reviewed By:
    #
    # Sets @user
    #
    # @return [Result::Base]
    #
    def fetch_user

      return validation_error(
          'um_l_fu_4',
          'invalid_api_params',
          ['email_not_allowed_for_dev_program'],
          GlobalConstant::ErrorAction.default
      ) unless Util::CommonValidator.is_whitelisted_email?(@email)

      @user = User.where(email: @email).first

      return validation_error(
          'um_l_fu_1',
          'invalid_api_params',
          ['email_not_registered'],
          GlobalConstant::ErrorAction.default
      ) if !@user.present? || !@user.password.present? || !@user.login_salt.present?

      return validation_error(
          'um_l_fu_2',
          'invalid_api_params',
          ['email_auto_blocked'],
          GlobalConstant::ErrorAction.default
      ) if @user.status == GlobalConstant::User.auto_blocked_status

      return validation_error(
          'um_l_fu_2',
          'invalid_api_params',
          ['email_inactive'],
          GlobalConstant::ErrorAction.default
      ) if (@user.status != GlobalConstant::User.active_status)

      success

    end

    # Decrypt login salt
    #
    # * Author: Alpesh
    # * Date: 15/01/2018
    # * Reviewed By:
    #
    # Sets @login_salt_d
    #
    # @return [Result::Base]
    #
    def decrypt_login_salt
      r = Aws::Kms.new('login','user').decrypt(@user.login_salt)
      return r unless r.success?

      @login_salt_d = r.data[:plaintext]

      success
    end

    # Validate password
    #
    # * Author: Alpesh
    # * Date: 15/01/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def validate_password

      evaluated_password_e = User.get_encrypted_password(@password, @login_salt_d)

      unless (evaluated_password_e == @user.password)
        user = User.where(id: @user.id).first # fetch again as KMS lookup might take time and we might have stale data
        user.failed_login_attempt_count ||= 0
        user.failed_login_attempt_count = user.failed_login_attempt_count + 1
        user.status = GlobalConstant::User.auto_blocked_status if user.failed_login_attempt_count >= 5
        user.save
        return validation_error(
            'um_l_fu_2',
            'invalid_api_params',
            ['password_incorrect'],
            GlobalConstant::ErrorAction.default
        )
      end

      success

    end

    # mark user's last logged in
    #
    # * Author: Anagha
    # * Date: 23/10/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def mark_user_logged_in
      User.where(['id = ?', @user.id]).update_all(['last_logged_in_at = ?', @logged_in_at])
      CacheManagement::User.new([@user.id]).clear

      success
    end

    # Set cookie value
    #
    # * Author: Alpesh
    # * Date: 15/01/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def set_cookie_value
      cookie_value = User.get_cookie_value(@user.id, @user.default_client_id, @user.password, @browser_user_agent, @logged_in_at)

      success_with_data(cookie_value: cookie_value)
    end

  end

end