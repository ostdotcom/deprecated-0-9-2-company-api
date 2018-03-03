# frozen_string_literal: true
module GlobalConstant

  class ClientAddress

    class << self

      ### Status Start ###

      def active_status
        'active'
      end

      def inactive_status
        'inactive'
      end

      ### Status End ###

      def default_ost_grant_amount
        10000
      end

      def default_eth_grant_amount
        0.1
      end

    end

  end

end
