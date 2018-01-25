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

      ### Setup Steps End ###

    end

  end

end
