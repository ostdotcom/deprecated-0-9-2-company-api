# frozen_string_literal: true
module GlobalConstant

  class User

    class << self

      ### Status Start ###

      def active_status
        'active'
      end

      def inactive_status
        'inactive'
      end

      # when user is auto blocked by system in case of multiple failed login events
      def auto_blocked_status
        'auto_blocked'
      end

      ### Status End ###

      ### Properties start ###

      def is_client_manager_property
        'is_client_manager'
      end

      def is_user_verified_property
        'user_verified'
      end

      ### Properties stop ###

    end

  end

end
