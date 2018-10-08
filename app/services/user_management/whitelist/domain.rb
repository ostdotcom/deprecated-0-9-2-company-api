module UserManagement
  
  module Whitelist
  
    class Domain < ServicesBase
    
      # Initialize
      #
      # * Author: Dhananjay
      # * Date: 14/09/2018
      # * Reviewed By: Sunil Khedar
      #
      # @param [String] email_domain (mandatory) - Email domain to be whitelisted
      #
      # @return [UserManagement::Whitelist::Domain]
      #
      def initialize(params)
        super
      
        @email_domain = @params[:email_domain]

        @domain = nil
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
      
        r = find_or_create_whitelisted_domain
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
  
        unless Util::CommonValidator.is_valid_email_domain?(@email_domain)
          return validation_error(
            'um_w_d_1',
            'invalid_api_params',
            ['invalid_email_domain'],
            GlobalConstant::ErrorAction.default
          )
        end

        # As email domain starts with @, remove the @ from domain. Example: @ost.com
        @domain = @email_domain.split('@')[1]
  
        success
      end

      # Find or create Whitelisted Domain
      #
      # * Author: Dhananjay
      # * Date: 14/09/2018
      # * Reviewed By: Sunil Khedar
      #
      # @return [Result::Base]
      #
      def find_or_create_whitelisted_domain
  
        wd = WhitelistedDomain.where(domain: @domain).first
        
        unless wd.present?
          wd = WhitelistedDomain.new
          wd.domain = @domain
          wd.save!
        end
  
        success
      end
      
    end
    
  end

end