module UserManagement

  class SignUp < ServicesBase

    # Initialize
    #
    # * Author: Alpesh
    # * Date: 11/01/2018
    # * Reviewed By: Sunil
    #
    # @param [String] email (mandatory) - the email of the user which is to be signed up
    # @param [String] password (mandatory) - user password
    # @params [String] browser_user_agent (mandatory) - browser user agent
    # @param [Integer] is_client_manager (mandatory) - 1 if the user is to be added as a client manager
    # @param [Integer] client_creation_needed (mandatory) - 1 if new client creation is needed
    # @param [String] token_name (mandatory) - token name
    # @param [String] token_symbol (mandatory) - token symbol
    # @param [String] token_icon (mandatory) - token symbol icon color code, until backend generate image
    # @param [String] agreed_terms_of_service (mandatory) - agreed_terms_of_service
    #
    # @return [UserManagement::SignUp]
    #
    def initialize(params)

      super

      @email = @params[:email]
      @password = @params[:password]
      @browser_user_agent = @params[:browser_user_agent]
      @is_client_manager = @params[:is_client_manager]
      @client_creation_needed = @params[:client_creation_needed]
      @token_name = @params[:token_name]
      @token_symbol = @params[:token_symbol]
      @token_symbol_icon = @params[:token_icon]
      @agreed_terms_of_service = @params[:agreed_terms_of_service]

      @client_id = nil
      @client_token_id = nil

      @login_salt_hash = nil
      @user = nil
      @cookie_value = nil

    end

    # Perform
    #
    # * Author: Alpesh
    # * Date: 11/01/2018
    # * Reviewed By: Sunil
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

      create_client_token

      set_cookie_value

      clear_cache

      enqueue_job

      success_with_data(
        cookie_value: @cookie_value
      )

    end

    private

    # Validate and sanitize
    #
    # * Author: Alpesh
    # * Date: 11/01/2018
    # * Reviewed By: Sunil
    #
    # @return [Result::Base]
    #
    def validate_and_sanitize

      @email = @email.to_s.downcase.strip
      @token_name = @token_name.to_s.strip
      @token_symbol = @token_symbol.to_s.strip

      validation_errors = {}
      validation_errors[:email] = 'The email address you entered is not valid.' unless Util::CommonValidator.is_valid_email?(@email)

      validation_errors[:password] = 'The password you entered is incorrect. Please try again.' unless Util::CommonValidator.is_valid_password?(@password)

      validation_errors[:agreed_terms_of_service] = 'Please read the Term & Conditions  and Polic of Use before registration.' unless @agreed_terms_of_service == 'on'

      validation_errors[:token_icon] = "Please select one icon for #{@token_name} for the list" if @token_symbol_icon.blank?

      r = validate_token_creation_params
      validation_errors.merge!(r.data) unless r.success?

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

      @is_client_manager = (@is_client_manager.to_i==1)
      @client_creation_needed = (@client_creation_needed.to_i==1)

      # NOTE: To be on safe side, check for generic errors as well
      r = validate
      return r unless r.success?

      success

    end

    # Validate token creation params
    #
    # * Author: Puneet
    # * Date: 02/02/2018
    # * Reviewed By: Sunil
    #
    # @return [Result::Base]
    #
    def validate_token_creation_params

      validation_errors = {}

      unless Util::CommonValidator.is_valid_token_symbol?(@token_symbol)
        validation_errors[:token_symbol] = 'Please enter from 3 to 4 letters or numbers. No special characters allowed. '
      end

      unless Util::CommonValidator.is_valid_token_name?(@token_name)
        validation_errors[:token_name] = 'Only letters, numbers and spaces allowed. (Max 20 characters)'
      end

      if Util::CommonValidator.has_stop_words?(@token_name)
        validation_errors[:token_name] = "Come on, the token name you entered is inappropriate. Please choose a nicer word."
      end

      if Util::CommonValidator.has_stop_words?(@token_symbol)
        validation_errors[:token_symbol] = "Come on, the token symbol you entered is inappropriate. Please choose a nicer word."
      end

      if ClientToken.where('name = ?', @token_name).first.present?
        validation_errors[:token_name] = "This token name is already in use. Please try a different one"
      end

      if ClientToken.where('symbol = ?', @token_symbol).first.present?
        validation_errors[:token_symbol] = "This token symbol is already in use. Please try a different one"
      end

      validation_errors.blank? ? success : error_with_data(
          'e_ct_4',
          'Token Creation params errors.',
          'Token Creation params errors.',
          GlobalConstant::ErrorAction.default,
          validation_errors
      )

    end

    # Find or create user
    #
    # * Author: Alpesh
    # * Date: 11/01/2018
    # * Reviewed By: Sunil
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
          {email: 'This email address is already in use. Please try logging in.'}
      ) if @user.present?

      r = init_user_obj_if_needed
      return r unless r.success?

      success
    end

    # Init user object
    #
    # * Author: Alpesh
    # * Date: 11/01/2018
    # * Reviewed By: Sunil
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

      @user.save! if @user.new_record? || @user.changed?

      success

    end

    # Create client
    #
    # * Author: Alpesh
    # * Date: 11/01/2018
    # * Reviewed By: Sunil
    #
    # Sets @client_id
    #
    def create_client
      return unless @client_creation_needed

      client = Client.new(
        status: GlobalConstant::Client.active_status
      )
      client.save!

      @client_id = client.id
    end

    # Create client manager
    #
    # * Author: Alpesh
    # * Date: 11/01/2018
    # * Reviewed By: Sunil
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

      @user.default_client_id = @client_id
      @user.send("set_#{GlobalConstant::User.is_client_manager_property}")
      @user.save!
    end

    # Create Client Token
    #
    # * Author: Puneet
    # * Date: 02/02/2018
    # * Reviewed By: Sunil
    #
    # Sets @client_token_id
    #
    def create_client_token

      ct = ClientToken.new(
          client_id: @client_id,
          name: @token_name,
          symbol: @token_symbol,
          symbol_icon: @token_symbol_icon,
          status: GlobalConstant::ClientToken.active_status,
          setup_steps: 0
      )

      ct.save!

      @client_token_id = ct.id

    end

    # Set cookie value
    #
    # * Author: Alpesh
    # * Date: 11/01/2018
    # * Reviewed By: Sunil
    #
    # Sets @cookie_value
    #
    def set_cookie_value
      @cookie_value = User.get_cookie_value(@user.id, @user.default_client_id, @user.password, @browser_user_agent)

      success
    end

    # Generate login salt
    #
    # * Author: Alpesh
    # * Date: 11/01/2018
    # * Reviewed By: Sunil
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

    # Clear cache
    #
    # * Author: Puneet
    # * Date: 11/01/2018
    # * Reviewed By: Sunil
    #
    # @return [Result::Base]
    #
    def clear_cache
      CacheManagement::User.new([@user.id]).clear
      CacheManagement::Client.new([@client_id]).clear
      CacheManagement::ClientToken.new([@client_token_id]).clear
      CacheManagement::ClientTokenSecure.new([@client_token_id]).clear
    end

    # Enqueue Job
    #
    # * Author: Pankaj
    # * Date: 14/02/2018
    # * Reviewed By: Sunil
    #
    # @return [Result::Base]
    #
    def enqueue_job
      BgJob.enqueue(
          SignupJob,
          {
              user_id: @user.id,
              client_id: @client_id,
              client_api_needed: @client_creation_needed,
              client_token_id: @client_token_id
          }
      )
    end

  end

end
