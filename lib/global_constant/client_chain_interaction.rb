# frozen_string_literal: true
module GlobalConstant

  class ClientChainInteraction

    class << self

      ########## activity_types #############

      def request_ost_activity_type
        'request_ost'
      end

      def transfer_to_staker_activity_type
        'transfer_to_staker'
      end

      ########## chain_types #############

      def utility_chain_type
        'utility'
      end

      def value_chain_type
        'value'
      end

      ########## Statuses #############

      def pending_status
        'pending'
      end

      def processed_status
        'processed'
      end

      def failed_status
        'failed'
      end

    end

  end

end
