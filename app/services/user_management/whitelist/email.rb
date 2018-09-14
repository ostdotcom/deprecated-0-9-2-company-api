module UserManagement
  
  module Whitelist
  
    class Email < ServicesBase
    
      # Initialize
      #
      # * Author: Dhananjay
      # * Date: 14/09/2018
      # * Reviewed By: Sunil Khedar
      #
      # @param [String] email (mandatory) - Email to be whitelisted
      #
      # @return [UserManagement::Whitelist::Email]
      #
      def initialize(params)
        super
      
        @email = @params[:email]
      end
    
      # Perform
      #
      # * Author: Dhananjay
      # * Date: 14/09/2018
      # * Reviewed By: Sunil Khedar
      #
      # @return [Result::Base]
      #
      def perform
      
        r = validate_and_sanitize
        return r unless r.success?
      
        r = find_or_create_whitelisted_email
        return r unless r.success?

        success
    
      end
    
      private
      
      # Validate and sanitize
      #
      # * Author: Dhananjay
      # * Date: 14/09/2018
      # * Reviewed By: Sunil Khedar
      #
      # @return [Result::Base]
      #
      def validate_and_sanitize
        r = validate
        return r unless r.success?
  
        unless Util::CommonValidator.is_valid_email?(@email)
          return validation_error(
            'um_w_e_1',
            'invalid_api_params',
            ['invalid_email'],
            GlobalConstant::ErrorAction.default
          )
        end
  
        success
      end

      # Find or create Whitelisted Email
      #
      # * Author: Dhananjay
      # * Date: 14/09/2018
      # * Reviewed By: Sunil Khedar
      #
      # @return [Result::Base]
      #
      def find_or_create_whitelisted_email
  
        we = WhitelistedEmail.where(email: @email).first
        
        unless we.present?
          we = WhitelistedEmail.new
          we.email = @email
          we.save!
        end
  
        success
      end
      
    end
    
  end

end