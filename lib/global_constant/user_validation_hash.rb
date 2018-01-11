# frozen_string_literal: true
module GlobalConstant

  class UserValidationHash

    class << self

      ### Status Start ###

      def active_status
        'active'
      end

      def blocked_status
        'blocked'
      end

      def inactive_status
        'inactive'
      end

      ### Status End ###


      ### Kind Start ###

      def reset_password
        'reset_password'
      end

      def double_optin
        'double_optin'
      end

      ### Kind End ###

    end

  end

end
