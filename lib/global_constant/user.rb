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

      def blocked_status
        'blocked'
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
