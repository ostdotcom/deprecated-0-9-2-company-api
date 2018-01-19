module UserManagement

  class SignUp < ServicesBase

    # Initialize
    #
    # * Author: Alpesh
    # * Date: 11/01/2018
    # * Reviewed By:
    #
    # @param [String] email (mandatory) - the email of the user which is to be signed up
    # @param [String] password (mandatory) - user password
    # @param [Integer] is_client_manager (mandatory) - 1 if the user is to be added as a client manager
    # @param [Integer] client_creation_needed (mandatory) - 1 if new client creation is needed
    #
    # @return [UserManagement::SignUp]
    #
    def initialize(params)
      super

      @email = @params[:email]
      @password = @params[:password]
      @is_client_manager = @params[:is_client_manager]
      @client_creation_needed = @params[:client_creation_needed]
      @client_id = @params[:client_id]

      @login_salt_hash = nil
      @info_salt_hash = nil
      @user_secret = nil
      @user = nil
      @cookie_value = nil
    end

    # Perform
    #
    # * Author: Alpesh
    # * Date: 11/01/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def perform

      r = validate_and_sanitize
      return r unless r.success?

      r = find_or_create_user
      return r unless r.success?

      create_client

      create_client_manager

      create_client_api_credentials

      set_cookie_value

      # TODO: Move this part in sidekiq
      create_user_email_service_api_call_hook

      UserManagement::SendDoubleOptInLink.new(email: @email).perform

      success_with_data(
        cookie_value: @cookie_value
      )

    end

    private

    # Validate and sanitize
    #
    # * Author: Alpesh
    # * Date: 11/01/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def validate_and_sanitize

      @email = @email.to_s.downcase.strip

      validation_errors = {}
      validation_errors[:email] = 'Please enter a valid email address' unless Util::CommonValidator.is_valid_email?(@email)

      # min char in password should be 8
      validation_errors[:password] = 'Password should be minimum 8 characters' if @password.to_s.length < 8

      return error_with_data(
        'um_su_1',
        'Registration Error',
        '',
        GlobalConstant::ErrorAction.default,
        {},
        validation_errors
      ) if validation_errors.present?

      return error_with_data(
        'um_su_2',
        'Invalid params.',
        '',
        GlobalConstant::ErrorAction.default,
        {},
        validation_errors
      ) if !Util::CommonValidator.is_boolean_string?(@is_client_manager) ||
        !Util::CommonValidator.is_boolean_string?(@client_creation_needed) ||
        (@client_creation_needed && !@is_client_manager)

      @is_client_manager = @is_client_manager.to_i==1
      @client_creation_needed = @client_creation_needed.to_i==1

      # NOTE: To be on safe side, check for generic errors as well
      r = validate
      return r unless r.success?

      success

    end

    # Find or create user
    #
    # * Author: Alpesh
    # * Date: 11/01/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def find_or_create_user
      @user = User.where(email: @email).first

      return error_with_data(
          'um_su_3',
          'Registration Error',
          '',
          GlobalConstant::ErrorAction.default,
          {},
          {email: 'Email address is already registered.'}
      ) if @user.present? &&
        @is_client_manager &&
        @user.send("#{GlobalConstant::User.is_client_manager_property}?")

      r = init_user_obj_if_needed
      Rails.logger.info("--------------------------------------------")
      Rails.logger.info(r)
      return r unless r.success?

      mark_user_as_client_manager

      @user.save! if @user.new_record? || @user.changed?

      success
    end

    # Init user object if needed
    #
    # * Author: Alpesh
    # * Date: 11/01/2018
    # * Reviewed By:
    #
    # Sets @user
    #
    # @return [Result::Base]
    #
    def init_user_obj_if_needed
      return success if @user.present?

      r = generate_login_salt
      return r unless r.success?

      password_e = User.get_encrypted_password(@password, @login_salt_hash[:plaintext])

      @user = User.new(
        email: @email,
        password: password_e,
        login_salt: @login_salt_hash[:ciphertext_blob],
        status: GlobalConstant::User.active_status
      )

      success
    end

    # Mark user as client manager
    #
    # * Author: Alpesh
    # * Date: 11/01/2018
    # * Reviewed By:
    #
    def mark_user_as_client_manager
      return unless @is_client_manager

      @user.send("set_#{GlobalConstant::User.is_client_manager_property}")
    end

    # Create client
    #
    # * Author: Alpesh
    # * Date: 11/01/2018
    # * Reviewed By:
    #
    # Sets @client_id
    #
    def create_client
      return unless @client_creation_needed

      generate_info_salt

      client = Client.new(
        info_salt: @info_salt_hash[:ciphertext_blob],
        status: GlobalConstant::Client.active_status
      )

      client.save!

      @user.default_client_id = client.id
      @user.save!

      @client_id = client.id
    end

    # Create client manager
    #
    # * Author: Alpesh
    # * Date: 11/01/2018
    # * Reviewed By:
    #
    # Sets @is_client_manager
    #
    def create_client_manager
      return unless @is_client_manager

      ClientManager.create!(
        client_id: @client_id,
        user_id: @user.id,
        status: GlobalConstant::ClientManager.active_status
      )
    end

    # Create client Api credentials
    #
    # * Author: Pankaj
    # * Date: 18/01/2018
    # * Reviewed By:
    #
    #
    #
    def create_client_api_credentials
      return unless @client_creation_needed

      api_credential = ClientApiCredential.new(
        client_id: @client_id,
        api_key: ClientApiCredential.generate_random_app_id,
        api_secret: ClientApiCredential.generate_encrypted_secret_key(@info_salt_hash[:plaintext])
      )

      api_credential.save!

    end

    # Set cookie value
    #
    # * Author: Alpesh
    # * Date: 11/01/2018
    # * Reviewed By:
    #
    # Sets @cookie_value
    #
    def set_cookie_value
      @cookie_value = User.get_cookie_value(
        @user.id,
        @user.default_client_id,
        @user.password
      )

      success
    end

    # Generate login salt
    #
    # * Author: Alpesh
    # * Date: 11/01/2018
    # * Reviewed By:
    #
    # Sets @login_salt_hash
    #
    # @return [Result::Base]
    #
    def generate_login_salt
      r = Aws::Kms.new('login', 'user').generate_data_key
      return r unless r.success?

      @login_salt_hash = r.data

      success
    end

    # Generate info salt
    #
    # * Author: Alpesh
    # * Date: 11/01/2018
    # * Reviewed By:
    #
    # Sets @info_salt_hash
    #
    # @return [Result::Base]
    #
    def generate_info_salt
      r = Aws::Kms.new('info', 'user').generate_data_key
      return r unless r.success?

      @info_salt_hash = r.data

      success
    end

    # Create Hook to sync data in Email Service
    #
    # * Author: Pankaj
    # * Date: 12/01/2018
    # * Reviewed By:
    #
    def create_user_email_service_api_call_hook

      Email::HookCreator::AddContact.new(
          email: @user.email,
          custom_attributes: {
              GlobalConstant::PepoCampaigns.user_registered_attribute => GlobalConstant::PepoCampaigns.user_registered_value
          }
      ).perform

    end

  end

end
