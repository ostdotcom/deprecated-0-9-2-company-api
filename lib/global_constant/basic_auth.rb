# frozen_string_literal: true
module GlobalConstant

  class BasicAuth < GlobalConstant::Base

    class << self

      def admin_username
        config['admin_username']
      end

      def admin_password
        config['admin_password']
      end

      private

      def config
        GlobalConstant::Base.basic_auth_config
      end

    end

  end

end
