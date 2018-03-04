module UserManagement

  class ResetPassword < ServicesBase

    # Initialize
    #
    # * Author: Pankaj
    # * Date: 11/01/2018
    # * Reviewed By:
    #
    # @params [String] r_t (mandatory) - token for reset
    # @params [String] password (mandatory) - this is the new password
    # @params [String] confirm_password (mandatory) - this is the confirm password
    #
    # @return [UserManagement::ResetPassword]
    #
    def initialize(params)
      super

      @r_t = @params[:r_t]
      @password = @params[:password]
      @confirm_password = @params[:confirm_password]

      @reset_token = nil
      @user_validation_hash_id = nil
      @user_validation_hash_obj = nil
      @user = nil
      @login_salt_d = nil
      @new_e_password = nil
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

      r = validate_and_sanitize
      return r unless r.success?

      fetch_user_validation_record

      r = validate_reset_token
      return r unless r.success?

      r = fetch_user
      return r unless r.success?

      r = decrypt_login_salt
      return r unless r.success?

      @new_e_password = User.get_encrypted_password(@password, @login_salt_d)

      r = validate_previous_password
      return r unless r.success?

      update_password

      r = update_user_validation_hashes_status
      return r unless r.success?

      clear_cache

      success

    end

    private

    # Validate and sanitize
    #
    # * Author: Pankaj
    # * Date: 11/01/2018
    # * Reviewed By:
    #
    # Sets @reset_token, @temporary_token_id
    #
    # @return [Result::Base]
    #
    def validate_and_sanitize

      validation_errors = {}

      validation_errors[:password] = 'Password should be minimum 8 characters' unless Util::CommonValidator.is_valid_password?(@password)
      validation_errors[:confirm_password] = 'Passwords do not match' if @confirm_password != @password

      return error_with_data(
          'um_cp_1',
          'Invalid password',
          '',
          GlobalConstant::ErrorAction.default,
          {},
          validation_errors
      ) if validation_errors.present?

      return invalid_url_error('um_rp_2') if @r_t.blank?

      # NOTE: To be on safe side, check for generic errors as well
      r = validate
      return r unless r.success?

      decryptor_obj = EmailTokenEncryptor.new(GlobalConstant::SecretEncryptor.email_tokens_key)
      r = decryptor_obj.decrypt(@r_t)
      return r unless r.success?

      decripted_t = r.data[:plaintext]

      splited_reset_token = decripted_t.split(':')

      return invalid_url_error('um_rp_3') if splited_reset_token.length != 2

      @reset_token = splited_reset_token[1].to_s

      @user_validation_hash_id = splited_reset_token[0].to_i

      success
    end

    # Fetch User validation record from token
    #
    # * Author: Pankaj
    # * Date: 11/01/2018
    # * Reviewed By:
    #
    # Sets @user_validation_hash_obj
    #
    def fetch_user_validation_record
      if @user_validation_hash_id > 0
        @user_validation_hash_obj = UserValidationHash.where(id: @user_validation_hash_id).first
      end
    end

    # Validate User Validation hash
    #
    # * Author: Pankaj
    # * Date: 11/01/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def validate_reset_token

      return invalid_url_error('um_rp_4') if @user_validation_hash_obj.blank?

      return invalid_url_error('um_rp_5') if @user_validation_hash_obj.validation_hash != @reset_token

      return invalid_url_error('um_rp_6') if @user_validation_hash_obj.status != GlobalConstant::UserValidationHash.active_status

      return invalid_url_error('um_rp_7') if @user_validation_hash_obj.is_expired?

      return invalid_url_error('um_rp_8') if @user_validation_hash_obj.kind != GlobalConstant::UserValidationHash.reset_password

      success

    end

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

      @user = User.where(id: @user_validation_hash_obj.user_id).first

      return unauthorized_access_response('um_rp_9') if @user.blank? || !@user.is_eligible_for_reset_passowrd?

      success

    end

    # Decrypt login salt
    #
    # * Author: Pankaj
    # * Date: 11/01/2018
    # * Reviewed By:
    #
    # Sets @login_salt_d
    #
    # @return [Result::Base]
    #
    def decrypt_login_salt
      r = Aws::Kms.new('login', 'user').decrypt(@user.login_salt)
      return r unless r.success?

      @login_salt_d = r.data[:plaintext]

      success
    end

    # Validate if new password is not equal to prev password
    #
    # * Author: Aman
    # * Date: 03/03/2018
    # * Reviewed By:
    #
    # Sets @new_e_password
    #
    def validate_previous_password

      return error_with_data(
          'um_cp_vpp_1',
          'Invalid password',
          '',
          GlobalConstant::ErrorAction.default,
          {},
          {password: 'Please use a new different password'}
      ) if @user.password == @new_e_password

      success

    end

    # Update password
    #
    # * Author: Pankaj
    # * Date: 11/01/2018
    # * Reviewed By:
    #
    def update_password
      @user.password = @new_e_password
      if GlobalConstant::User.auto_blocked_status == @user.status
        # if we had blocked a user for more than a threshhold failed login attemps we set status to blocked
        # now we should reset it to active
        @user.status = GlobalConstant::User.active_status
        @user.failed_login_attempt_count = 0
      end
      @user.save!
    end

    # Update User Validation hash used in resetting password and make all others inactive.
    #
    # * Author: Pankaj
    # * Date: 11/01/2018
    # * Reviewed By:
    #
    def update_user_validation_hashes_status
      @user_validation_hash_obj.status = GlobalConstant::UserValidationHash.used_status
      @user_validation_hash_obj.save!

      UserValidationHash.where(
          user_id: @user.id,
          kind: GlobalConstant::UserValidationHash.reset_password,
          status: GlobalConstant::UserValidationHash.active_status
      ).update_all(
          status: GlobalConstant::UserValidationHash.inactive_status
      )
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
      CacheManagement::UserSecure.new([@user.id]).clear
    end

    # Invalid User access response
    #
    # * Author: Pankaj
    # * Date: 11/01/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def unauthorized_access_response(err, display_text = 'Invalid User')
      error_with_data(
          err,
          display_text,
          display_text,
          GlobalConstant::ErrorAction.default,
          {}
      )
    end

    # Invalid Request Response
    #
    # * Author: Pankaj
    # * Date: 11/01/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def invalid_url_error(code)
      error_with_data(
          code,
          'Invalid URL',
          'Invalid URL',
          GlobalConstant::ErrorAction.default,
          {}
      )
    end

  end

end
