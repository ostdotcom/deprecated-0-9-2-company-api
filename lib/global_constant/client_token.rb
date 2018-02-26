# frozen_string_literal: true
module GlobalConstant

  class ClientToken

    class << self

      ### Status Start ###

      def active_status
        'active'
      end

      def inactive_status
        'inactive'
      end

      ### Status End ###

      ### Setup Steps Start ###

      def token_worth_in_usd_setup_step
        'token_worth_in_usd'
      end

      def configure_transactions_setup_step
        'configure_transactions'
      end

      def propose_initiated_setup_step
        'propose_initiated'
      end

      def propose_done_setup_step
        'propose_done'
      end

      def registered_on_uc_setup_step
        'registered_on_uc'
      end

      def registered_on_vc_setup_step
        'registered_on_vc'
      end

      def received_test_ost_setup_step
        'received_test_ost'
      end

      def airdrop_done_setup_step
        'airdrop_setup_done'
      end

      ### Setup Steps End ###

    end

  end

end
