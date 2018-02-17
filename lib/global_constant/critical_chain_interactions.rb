# frozen_string_literal: true
module GlobalConstant

  class CriticalChainInteractions

    class << self

      ########## activity_types #############

      def request_ost_activity_type
        'request_ost'
      end

      def transfer_to_staker_activity_type
        'transfer_to_staker'
      end

      def grant_eth
        'grant_eth'
      end

      def propose_initiates_activity_type
        'propose_initiates'
      end

      def staker_initial_transfer_activity_type
        'staker_initial_transfer'
      end

      def stake_approval_started_activity_type
        'stake_approval_started'
      end

      def stake_started_activity_type
        'stake_started'
      end

      ########## chain_types #############

      def utility_chain_type
        'utility'
      end

      def value_chain_type
        'value'
      end

      ########## Statuses #############

      def queued_status
        'queued'
      end

      def pending_status
        'pending'
      end

      def processed_status
        'processed'
      end

      def failed_status
        'failed'
      end

      def timeout_status
        'time_out'
      end

    end

  end

end
