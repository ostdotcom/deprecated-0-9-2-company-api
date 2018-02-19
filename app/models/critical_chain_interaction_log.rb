class CriticalChainInteractionLog < EstablishCompanyBigDbConnection

  enum activity_type: {
    GlobalConstant::CriticalChainInteractions.request_ost_activity_type => 1,
    GlobalConstant::CriticalChainInteractions.transfer_to_staker_activity_type => 2,
    GlobalConstant::CriticalChainInteractions.grant_eth_activity_type => 3,
    GlobalConstant::CriticalChainInteractions.propose_bt_activity_type => 4,
    GlobalConstant::CriticalChainInteractions.staker_initial_transfer_activity_type => 5,
    GlobalConstant::CriticalChainInteractions.stake_approval_started_activity_type => 6,
    GlobalConstant::CriticalChainInteractions.stake_bt_started_activity_type => 7,
    GlobalConstant::CriticalChainInteractions.stake_st_prime_started_activity_type => 8
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

  serialize :request_params, Hash
  serialize :response_data, Hash

  MARK_AS_TIMED_OUT_AFTER = 30.minutes

  # check if pending?
  def is_pending?
    [
      GlobalConstant::CriticalChainInteractions.queued_status,
      GlobalConstant::CriticalChainInteractions.pending_status
    ].include?(self.status)
  end

  # check if precessed?
  def is_processed?
    self.status == GlobalConstant::CriticalChainInteractions.processed_status
  end

  # check if failed?
  def is_failed?
    [
      GlobalConstant::CriticalChainInteractions.failed_status,
      GlobalConstant::CriticalChainInteractions.timeout_status
    ].include?(self.status)
  end

  # check if interaction can be marked as time_out
  def can_be_marked_timeout?
    Time.now.to_i - self.created_at > MARK_AS_TIMED_OUT_AFTER
  end

end