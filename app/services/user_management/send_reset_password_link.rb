module UserManagement

  class SendResetPasswordLink < ServicesBase

    # Initialize
    #
    # * Author: Pankaj
    # * Date: 11/01/2018
    # * Reviewed By:
    #
    # @params [String] email (mandatory) - this is the email entered
    #
    # @return [UserManagement::SendResetPasswordLink]
    #
    def initialize(params)

      super

      @email = @params[:email]

      @user = nil
      @reset_password_token = nil

    end

    # Perform
    #
    # * Author: Pankaj
    # * Date: 11/01/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def perform

      r = validate
      return r unless r.success?

      r = fetch_user
      return r unless r.success?

      r = create_reset_password_token
      return r  unless r.success?

      send_forgot_password_mail

      success
    end

    private

    # Fetch user
    #
    # * Author: Pankaj
    # * Date: 11/01/2018
    # * Reviewed By:
    #
    # Sets @user
    #
    # @return [Result::Base]
    #
    def fetch_user

      @user = User.where(email: @email).first

      error_key = ''
      if @user.blank?
        error_key = 'unrecognized_email'
      elsif !@user.is_eligible_for_reset_passowrd?
        error_key = 'email_inactive'
      end

      return validation_error(
          'um_srpl_1',
          'invalid_api_params',
          [error_key],
          GlobalConstant::ErrorAction.default
      ) if error_key.present?

      success

    end

    # Create Reset Password Token
    #
    # * Author: Pankaj
    # * Date: 11/01/2018
    # * Reviewed By:
    #
    # Sets @reset_password_token
    #
    # @return [Result::Base]
    #
    def create_reset_password_token

      reset_token = LocalCipher.get_sha_hashed_text(
          "#{@user.id}::#{@user.password}::#{Time.now.to_i}::reset_password::#{rand}"
      )

      db_row = UserValidationHash.create!(
        user_id: @user.id, kind: GlobalConstant::UserValidationHash.reset_password,
        validation_hash: reset_token, status: GlobalConstant::UserValidationHash.active_status
      )

      reset_pass_token_str = "#{db_row.id.to_s}:#{reset_token}"
      encryptor_obj = EmailTokenEncryptor.new(GlobalConstant::SecretEncryptor.email_tokens_key)
      r = encryptor_obj.encrypt(reset_pass_token_str)
      return r unless r.success?

      @reset_password_token = r.data[:ciphertext_blob]

      success

    end

    # Send forgot password_mail
    #
    # * Author: Pankaj
    # * Date: 11/01/2018
    # * Reviewed By:
    #
    def send_forgot_password_mail
      Email::HookCreator::SendTransactionalMail.new(
          email: @user.email,
          template_name: GlobalConstant::PepoCampaigns.forgot_password_template,
          template_vars: {
              reset_password_token: CGI.escape(@reset_password_token),
              company_web_root_url: GlobalConstant::CompanyWeb.root_url
          }
      ).perform
    end

  end
end
