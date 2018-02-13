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
    #
    # @return [UserManagement::Login]
    #
    def initialize(params)
      super

      @email = @params[:email]
      @password = @params[:password]

      @user = nil
      @login_salt_d = nil
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
      @user = User.where(email: @email).first

      return unauthorized_access_response('um_l_1') if !@user.present? ||
        !@user.password.present? ||
        (@user.status != GlobalConstant::User.active_status) ||
        !@user.login_salt.present?

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
        user.failed_login_attempt_count = use.failed_login_attempt_count + 1
        user.status = GlobalConstant::User.blocked_status if user.failed_login_attempt_count >= 5
        user.save
        return unauthorized_access_response('um_l_2')
      end

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
      cookie_value = User.get_cookie_value(@user.id, @user.default_client_id, @user.password)

      success_with_data(cookie_value: cookie_value)
    end

    # Unauthorized access response
    #
    # * Author: Alpesh
    # * Date: 15/01/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
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