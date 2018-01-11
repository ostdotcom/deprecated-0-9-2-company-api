# frozen_string_literal: true
module GlobalConstant

  class Cookie

    class << self

      def user_cookie_name
        'ca'
      end

      def user_expiry
        300.minutes
      end

    end

  end

end
