module UserManagement

  class SendDoubleOptInLink < ServicesBase

    # Initialize
    #
    # * Author: Pankaj
    # * Date: 15/01/2018
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
      @double_optin_token = nil

    end

    # Perform
    #
    # * Author: Pankaj
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

      r = create_double_opt_in_token
      return r  unless r.success?

      send_double_optin_email

      success

    end

    private

    # Fetch user
    #
    # * Author: Pankaj
    # * Date: 15/01/2018
    # * Reviewed By:
    #
    # Sets @user
    #
    # @return [Result::Base]
    #
    def fetch_user
      @user = User.where(email: @email).first

      return validation_error(
          'um_srpl_1',
          'invalid_api_params',
          ['unrecognized_email'],
          GlobalConstant::ErrorAction.default
      ) unless @user.present? && (@user.status == GlobalConstant::User.active_status)

      success

    end

    # Create Double Opt In Token
    #
    # * Author: Pankaj
    # * Date: 15/01/2018
    # * Reviewed By:
    #
    # Sets @double_optin_token
    #
    # @return [Result::Base]
    #
    def create_double_opt_in_token
      double_opt_in_token = LocalCipher.get_sha_hashed_text("#{@user.id}::#{@user.password}::#{Time.now.to_i}::double_optin::#{rand}")
      db_row = UserValidationHash.create!(user_id: @user.id, kind: GlobalConstant::UserValidationHash.double_optin,
                                          validation_hash: double_opt_in_token, status: GlobalConstant::UserValidationHash.active_status)

      double_opt_in_token_str = "#{db_row.id.to_s}:#{double_opt_in_token}"
      encryptor_obj = EmailTokenEncryptor.new(GlobalConstant::SecretEncryptor.email_tokens_key)
      r = encryptor_obj.encrypt(double_opt_in_token_str)
      return r unless r.success?

      @double_optin_token = r.data[:ciphertext_blob]

      success
    end

    # Send Double OptIn mail
    #
    # * Author: Pankaj
    # * Date: 15/01/2018
    # * Reviewed By:
    #
    def send_double_optin_email
      Email::HookCreator::SendTransactionalMail.new(
          email: @user.email,
          template_name: GlobalConstant::PepoCampaigns.double_opt_in_template,
          template_vars: {
              double_opt_in_token: CGI.escape(@double_optin_token),
              company_web_domain: GlobalConstant::CompanyWeb.domain
          }
      ).perform
    end

  end
end
