# frozen_string_literal: true
module GlobalConstant

  #NOTE: This is a shared DB with SAAS. ANY Changes here should be synced with SAAS
  class CriticalChainInteractions

    class << self

      ########## activity_types #############

      def request_ost_activity_type
        'request_ost'
      end

      def transfer_to_staker_activity_type
        'transfer_to_staker'
      end

      def grant_eth_activity_type
        'grant_eth'
      end

      def propose_bt_activity_type
        'propose_bt'
      end

      def staker_initial_transfer_activity_type
        'staker_initial_transfer'
      end

      def stake_approval_started_activity_type
        'stake_approval_started'
      end

      def stake_bt_started_activity_type
        'stake_bt_started'
      end

      def stake_st_prime_started_activity_type
        'stake_st_prime_started'
      end

      def deploy_airdrop_activity_type
        'deploy_airdrop'
      end

      def set_worker_activity_type
        'set_worker'
      end

      def set_price_oracle_activity_type
        'set_price_oracle'
      end

      def set_accepted_margin_activity_type
        'set_accepted_margin'
      end

      def setops_airdrop_activity_type
        'setops_airdrop'
      end

      def airdrop_users_activity_type
        'airdrop_users'
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

      def activity_types_to_mark_pending
        [
            GlobalConstant::CriticalChainInteractions.propose_bt_activity_type,
            GlobalConstant::CriticalChainInteractions.staker_initial_transfer_activity_type,
            GlobalConstant::CriticalChainInteractions.airdrop_users_activity_type
        ]
      end

    end

  end

end
