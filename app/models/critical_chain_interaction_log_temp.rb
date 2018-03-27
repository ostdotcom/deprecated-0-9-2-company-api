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
    (Time.now.to_i - self.created_at.to_i) > MARK_AS_TIMED_OUT_AFTER
  end

  after_commit :flush_cache

  # Flush memcache
  #
  # * Author: Puneet
  # * Date: 01/02/2018
  # * Reviewed By:
  #
  def flush_cache

    id_to_flush = parent_id.present? ? parent_id : id
    CacheManagement::CriticalChainInteractionStatus.new([id_to_flush]).clear

    # This can be optimized later
    CacheManagement::PendingCriticalInteractionIds.new([client_token_id]).clear if client_token_id.present?

    if [
        GlobalConstant::CriticalChainInteractions.timeout_status,
        GlobalConstant::CriticalChainInteractions.failed_status
    ].include?(self.status)

      ApplicationMailer.notify(
          body: {},
          data: {
              'previous_status' => self.status_before_last_save,
              'current_status' => self.status,
              'chain_interaction_log_id' => self.id,
              'activity_type' => self.activity_type
          },
          subject: 'Critical Chain Interaction Status Marked as ' + self.status
      ).deliver

    end

  end

end