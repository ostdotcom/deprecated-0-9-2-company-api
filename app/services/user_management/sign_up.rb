module UserManagement

  class SignUp < ServicesBase

    def initialize(params)
      super

      @email = @params[:email]
      @password = @params[:password]
      @browser_user_agent = @params[:browser_user_agent]
      @ip_address = @params[:ip_address]
      @geoip_country = @params[:geoip_country]

      @utm_params = @params[:utm_params]

      @login_salt_hash = nil
      @user_secret = nil
      @user = nil
    end

    def perform

      r = validate_and_sanitize
      return r unless r.success?

      r = check_if_email_already_registered
      return r unless r.success?

      r = generate_login_salt
      return r unless r.success?

      create_user

      enqueue_job

      set_cookie_value

    end

    private

    def validate_and_sanitize

      @email = @email.to_s.downcase.strip

      validation_errors = {}
      if !Util::CommonValidator.is_valid_email?(@email)
        validation_errors[:email] = 'Please enter a valid email address'
      end

      if @password.length < 8
        validation_errors[:password] = 'Password should be minimum 8 characters'
      end

      return error_with_data(
          'um_su_1',
          'Registration Error',
          '',
          GlobalConstant::ErrorAction.default,
          {},
          validation_errors
      ) if validation_errors.present?

      # NOTE: To be on safe side, check for generic errors as well
      r = validate
      return r unless r.success?

      success
    end

    def check_if_email_already_registered
      user = User.where(email: @email).first

      return error_with_data(
          'um_su_2',
          'Registration Error',
          '',
          GlobalConstant::ErrorAction.default,
          {},
          {email: 'Email address is already registered'}
      ) if user.present?

      success
    end

    def generate_login_salt
      r = Aws::Kms.new('login', 'user').generate_data_key
      return r unless r.success?

      @login_salt_hash = r.data

      success
    end

    def create_user
      # first insert into user_secrets and use it's id in users table
      @user_secret = UserSecret.create!(login_salt: @login_salt_hash[:ciphertext_blob])

      password_e = User.get_encrypted_password(@password, @login_salt_hash[:plaintext])

      @user = User.create!(
          email: @email,
          password: password_e,
          user_secret_id: @user_secret.id,
          status: GlobalConstant::User.active_status
      )
    end

    def enqueue_job
      BgJob.enqueue(
          NewUserRegisterJob,
          {
              user_id: @user.id,
              utm_params: @utm_params,
              ip_address: @ip_address,
              browser_user_agent: @browser_user_agent,
              geoip_country: @geoip_country
          }
      )
    end

    def set_cookie_value
      cookie_value = User.get_cookie_value(@user.id, @user.password, @browser_user_agent)
      success_with_data(cookie_value: cookie_value)
    end

  end

end
