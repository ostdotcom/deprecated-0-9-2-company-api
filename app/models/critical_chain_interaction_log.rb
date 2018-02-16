class CriticalChainInteractionLog < EstablishCompanyBigDbConnection

  enum activity_type: {
      GlobalConstant::CriticalChainInteractions.request_ost_activity_type => 1,
      GlobalConstant::CriticalChainInteractions.transfer_to_staker_activity_type => 2
  }

  enum chain_type: {
      GlobalConstant::CriticalChainInteractions.value_chain_type => 1,
      GlobalConstant::CriticalChainInteractions.utility_chain_type => 2
  }

  enum status: {
      GlobalConstant::CriticalChainInteractions.pending_status => 1,
      GlobalConstant::CriticalChainInteractions.processed_status => 2,
      GlobalConstant::CriticalChainInteractions.failed_status => 3
  }

  scope :of_activity_type, ->(activity_type) {
    where(activity_type: activity_type)
  }

  serialize :debug_data, Hash

end