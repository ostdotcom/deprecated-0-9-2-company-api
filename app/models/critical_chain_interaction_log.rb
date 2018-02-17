class CriticalChainInteractionLog < EstablishCompanyBigDbConnection

  enum activity_type: {
    GlobalConstant::CriticalChainInteractions.request_ost_activity_type => 1,
    GlobalConstant::CriticalChainInteractions.transfer_to_staker_activity_type => 2,
    GlobalConstant::CriticalChainInteractions.grant_eth => 3,
    GlobalConstant::CriticalChainInteractions.propose_initiates_activity_type => 4,
    GlobalConstant::CriticalChainInteractions.staker_initial_transfer_activity_type => 5,
    GlobalConstant::CriticalChainInteractions.stake_approval_started_activity_type => 6,
    GlobalConstant::CriticalChainInteractions.stake_started_activity_type => 7
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

  scope :of_activity_type, ->(activity_type) {
    where(activity_type: activity_type)
  }

  serialize :debug_data, Hash

end