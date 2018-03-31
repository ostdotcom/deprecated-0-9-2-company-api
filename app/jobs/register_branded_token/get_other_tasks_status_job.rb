class RegisterBrandedToken::GetOtherTasksStatusJob < ApplicationJob

  include Util::ResultHelper

  queue_as GlobalConstant::Sidekiq.queue_name :default_medium_priority_queue

  # Perform
  #
  # * Author: Puneet
  # * Date: 29/03/2018
  # * Reviewed By: 
  #
  # @param [Integer] parent_id (mandatory) - parent id of next tasks in chain
  #
  def perform(params)

    init_params(params)

    r = validate
    return r unless r.success?

    update_client_token_flags

    enqueue_self if @re_enqueue_needed

    success

  end

  private

  # init params
  #
  # * Author: Puneet
  # * Date: 29/03/2018
  # * Reviewed By: 
  #
  def init_params(params)

    @parent_id = params[:parent_id]

    @parent_critical_chain_interaction_log = nil
    @client_id = nil
    @re_enqueue_needed = false

  end

  # Validate params
  #
  # * Author: Puneet
  # * Date: 29/03/2018
  # * Reviewed By: 
  #
  # Sets @parent_critical_chain_interaction_log
  #
  # @return [Result::Base]
  #
  def validate

    @parent_critical_chain_interaction_log = CriticalChainInteractionLog.where(
        id: @parent_id
    ).first

    return error_with_data(
        'j_s_gasj_1',
        'Critical chain interation log id not found.',
        'Critical chain interation log id not found.',
        GlobalConstant::ErrorAction.default,
        {}
    ) if @parent_critical_chain_interaction_log.blank?

    @client_id = @parent_critical_chain_interaction_log.client_id

    success

  end

  # Update Client Token Flags
  #
  # * Author: Puneet
  # * Date: 29/03/2018
  # * Reviewed By:
  #
  def update_client_token_flags

    statuses = CriticalChainInteractionLog.where(parent_id: @parent_id).
      where(activity_type: [
        CriticalChainInteractionLog::activity_types[GlobalConstant::CriticalChainInteractions.set_worker_activity_type.to_sym],
        CriticalChainInteractionLog::activity_types[GlobalConstant::CriticalChainInteractions.set_price_oracle_activity_type],
        CriticalChainInteractionLog::activity_types[GlobalConstant::CriticalChainInteractions.set_accepted_margin_activity_type]
      ]).select(:id, :status).collect(&:status)

    return if statuses.include?(GlobalConstant::CriticalChainInteractions.failed_status) ||
        statuses.include?(GlobalConstant::CriticalChainInteractions.timeout_status)

    @re_enqueue_needed = statuses.include?(GlobalConstant::CriticalChainInteractions.pending_status) ||
        statuses.include?(GlobalConstant::CriticalChainInteractions.queued_status)

    return if @re_enqueue_needed

    # if all 3 are processed
    if statuses.length == 3
      client_token = ClientToken.where(id: @parent_critical_chain_interaction_log.client_token_id).first
      client_token.send("set_#{GlobalConstant::ClientToken.setup_complete_step}")
      client_token.save!
      CacheManagement::ClientToken.new([@parent_critical_chain_interaction_log.client_token_id]).clear
    end

  end

  # Enqueue job
  #
  # * Author: alpesh
  # * Date: 22/02/2018
  # * Reviewed By:
  #
  def enqueue_self

    BgJob.enqueue(
      ::RegisterBrandedToken::GetOtherTasksStatusJob,
      {
          parent_id: @parent_id
      },
      {
          wait: 30.seconds
      }
    )

  end

end
