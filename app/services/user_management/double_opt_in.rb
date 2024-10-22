module UserManagement

  class DoubleOptIn < ServicesBase

    # Initialize
    #
    # * Author: Pankaj
    # * Date: 16/01/2018
    # * Reviewed By:
    #
    # @params [String] r_t (mandatory) - token for double opt in
    #
    # @return [UserManagement::DoubleOptIn]
    #
    def initialize(params)

      super

      @r_t = @params[:r_t]
      @user_id = @params[:user_id]

      @token = nil
      @user_validation_hash_id = nil
      @user_validation_hash_obj = nil
      @user = nil

    end

    # Perform
    #
    # * Author: Pankaj
    # * Date: 16/01/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def perform

      r = validate_and_sanitize
      return r unless r.success?

      r = fetch_logged_in_user
      return r unless r.success?

      return success if @user.send("#{GlobalConstant::User.is_user_verified_property}?")

      fetch_user_validation_record

      r = validate_double_opt_token
      return r unless r.success?

      r = update_user_validation_hashes_status
      return r unless r.success?

      create_update_contact_email_service_hook

      mark_user_verified

      success

    end

    private

    # Validate and sanitize
    #
    # * Author: Pankaj
    # * Date: 16/01/2018
    # * Reviewed By:
    #
    # Sets @reset_token, @temporary_token_id
    #
    # @return [Result::Base]
    #
    def validate_and_sanitize

      return invalid_url_error('um_doi_1') if @r_t.blank?

      # NOTE: To be on safe side, check for generic errors as well
      r = validate
      return r unless r.success?

      decryptor_obj = EmailTokenEncryptor.new(GlobalConstant::SecretEncryptor.email_tokens_key)
      r = decryptor_obj.decrypt(@r_t)

      return r unless r.success?

      decripted_t = r.data[:plaintext]

      splited_reset_token = decripted_t.split(':')

      return invalid_url_error('um_doi_2') if splited_reset_token.length != 2

      @token = splited_reset_token[1].to_s

      @user_validation_hash_id = splited_reset_token[0].to_i

      @user_id = @user_id.to_i

      success

    end

    # Fetch logged in User
    #
    # * Author: Puneet
    # * Date: 16/02/2018
    # * Reviewed By:
    #
    # Sets @user
    #
    def fetch_logged_in_user

      @user = User.where(id: @user_id).first

      return validation_error(
        'um_dop_3',
        'invalid_api_params',
        ['invalid_user_id'],
        GlobalConstant::ErrorAction.default
      ) if @user.blank? || @user[:status] != GlobalConstant::User.active_status

      success

    end

    # Fetch User validation record from token
    #
    # * Author: Pankaj
    # * Date: 16/01/2018
    # * Reviewed By:
    #
    # Sets @user_validation_hash_obj
    #
    def fetch_user_validation_record
      @user_validation_hash_obj = UserValidationHash.where(id: @user_validation_hash_id).first
    end

    # Validate User Validation hash
    #
    # * Author: Pankaj
    # * Date: 16/01/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def validate_double_opt_token

      return invalid_url_error('um_doi_3') if @user_validation_hash_obj.blank?

      return invalid_url_error('um_doi_4') if @user_validation_hash_obj.validation_hash != @token

      return invalid_url_error('um_doi_5') if @user_validation_hash_obj.status != GlobalConstant::UserValidationHash.active_status

      return invalid_url_error('um_doi_6') if @user_validation_hash_obj.is_expired?

      return invalid_url_error('um_doi_7') if @user_validation_hash_obj.kind != GlobalConstant::UserValidationHash.double_optin

      return unauthorized_access_response('um_doi_8') if @user_validation_hash_obj.user_id != @user_id

      success

    end

    # Create update contact email hook
    #
    # * Author: Pankaj
    # * Date: 16/01/2018
    # * Reviewed By:
    #
    def create_update_contact_email_service_hook
      Email::HookCreator::UpdateContact.new(
        email: @user.email,
        custom_attributes: {
          GlobalConstant::PepoCampaigns.double_optin_done_attribute => GlobalConstant::PepoCampaigns.double_optin_done_value
        },
        user_settings: {
          GlobalConstant::PepoCampaigns.double_opt_in_status_user_setting => GlobalConstant::PepoCampaigns.verified_value
        }
      ).perform
    end

    # Mark user as verified.
    #
    # * Author: Pankaj
    # * Date: 16/01/2018
    # * Reviewed By:
    #
    def mark_user_verified
      @user.send("set_#{GlobalConstant::User.is_user_verified_property}")
      @user.save!
      clear_cache
    end

    # Update User Validation hash used for double opt in and make all others inactive.
    #
    # * Author: Pankaj
    # * Date: 16/01/2018
    # * Reviewed By:
    #
    def update_user_validation_hashes_status
      @user_validation_hash_obj.status = GlobalConstant::UserValidationHash.used_status
      @user_validation_hash_obj.save!

      UserValidationHash.where(
        user_id: @user_id,
        kind: GlobalConstant::UserValidationHash.double_optin,
        status: GlobalConstant::UserValidationHash.active_status
      ).update_all(
        status: GlobalConstant::UserValidationHash.inactive_status
      )
      success
    end

    # Invalid User access response
    #
    # * Author: Pankaj
    # * Date: 16/01/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def unauthorized_access_response(err)
      validation_error(
        err,
        'invalid_api_params',
        ['invalid_r_t'],
        GlobalConstant::ErrorAction.default
      )
    end

    # Invalid Request Response
    #
    # * Author: Pankaj
    # * Date: 16/01/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def invalid_url_error(code)
      validation_error(
        code,
        'invalid_api_params',
        ['invalid_r_t'],
        GlobalConstant::ErrorAction.default
      )
    end

    #
    # * Author: Puneet
    # * Date: 11/01/2018
    # * Reviewed By
    #
    # @return [Result::Base]
    #
    def clear_cache
      CacheManagement::User.new([@user_id]).clear
    end

  end

end
