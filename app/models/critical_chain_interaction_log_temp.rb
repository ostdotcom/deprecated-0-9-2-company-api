class CriticalChainInteractionLogTemp < EstablishCompanyBigDbConnection

  self.table_name = 'critical_chain_interaction_logs'

  #TODO: To be deleted after data is moved to new table

  enum activity_type: {
      GlobalConstant::CriticalChainInteractions.request_ost_activity_type => 1,
      GlobalConstant::CriticalChainInteractions.transfer_to_staker_activity_type => 2,
      GlobalConstant::CriticalChainInteractions.grant_eth_activity_type => 3,
      GlobalConstant::CriticalChainInteractions.propose_bt_activity_type => 4,
      GlobalConstant::CriticalChainInteractions.staker_initial_transfer_activity_type => 5,
      GlobalConstant::CriticalChainInteractions.stake_approval_started_activity_type => 6,
      GlobalConstant::CriticalChainInteractions.stake_bt_started_activity_type => 7,
      GlobalConstant::CriticalChainInteractions.stake_st_prime_started_activity_type => 8,
      GlobalConstant::CriticalChainInteractions.airdrop_users_activity_type => 9,
      GlobalConstant::CriticalChainInteractions.deploy_airdrop_activity_type => 10,
      GlobalConstant::CriticalChainInteractions.setops_airdrop_activity_type => 11,
      GlobalConstant::CriticalChainInteractions.set_worker_activity_type => 12,
      GlobalConstant::CriticalChainInteractions.set_price_oracle_activity_type => 13,
      GlobalConstant::CriticalChainInteractions.set_accepted_margin_activity_type => 14
  }

  enum chain_type: {
      GlobalConstant::CriticalChainInteractions.value_chain_type => 1,
      GlobalConstant::CriticalChainInteractions.utility_chain_type => 2
  }

  enum status: {
      GlobalConstant::CriticalChainInteractions.queued_status => 1,
      GlobalConstant::CriticalChainInteractions.pending_status => 2,
      GlobalConstant::CriticalChainInteractions.processed_status => 3,
      GlobalConstant::CriticalChainInteractions.failed_status => 4,
      GlobalConstant::CriticalChainInteractions.timeout_status => 5
  }

  serialize :request_params, Hash
  serialize :response_data, Hash

end