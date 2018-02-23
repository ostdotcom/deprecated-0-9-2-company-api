# frozen_string_literal: true
module GlobalConstant

  class Client

    class << self

      ### Status Start ###

      def active_status
        'active'
      end

      def inactive_status
        'inactive'
      end

      ### Status End ###

      def default_initial_users
        25
      end

      def max_initial_bt_airdrop_amount
        10
      end

      # If 1 BT's are to be airdropped we would recommend minting buffer_mint_factor_over_airdrop
      def buffer_mint_factor_over_airdrop
        4
      end

    end

  end

end
