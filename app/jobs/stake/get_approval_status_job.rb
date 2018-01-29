class Stake::GetApprovalStatusJob < ApplicationJob

  include Util::ResultHelper

  queue_as GlobalConstant::Sidekiq.queue_name :default_medium_priority_queue

  # Perform
  #
  # * Author: Kedar
  # * Date: 29/01/2018
  # * Reviewed By:
  #
  # @param [String] transation_hash (mandatory) - transaction hash of the approval transaction
  # @param [Hash] stake_params (mandatory) - Stake params
  #
  def perform(params)

    init_params(params)

    r = get_approval_status
    return unless r.success?

    enqueue_job

  end

  private

  # init params
  #
  # * Author: Kedar
  # * Date: 29/01/2018
  # * Reviewed By:
  #
  # @param [Hash] params
  #
  def init_params(params)
    @transaction_hash = params[:transaction_hash]
    @stake_params = params[:stake_params]

    @approval_done = false
  end

  # Get Approval Status
  #
  # * Author: Kedar
  # * Date: 29/01/2018
  # * Reviewed By:
  #
  # @return [Result::Base]
  #
  def get_approval_status
    params = {
      transaction_hash: @transaction_hash
    }

    r = SaasApi::Stake::GetApprovalStatus.new.perform(params)
    return r unless r.success?

    @approval_done = true

    success
  end

  # Enqueue job
  #
  # * Author: Kedar
  # * Date: 29/01/2018
  # * Reviewed By:
  #
  def enqueue_job
    if approval_done?

      BgJob.enqueue(
        Stake::StartJob,
        @stake_params
      )

    else

      BgJob.enqueue(
        Stake::GetApprovalStatusJob,
        {
          transaction_hash: @transaction_hash,
          stake_params: @stake_params
        },
        {
          wait: 30.seconds
        }
      )

    end

  end

  # Is approval done
  #
  # * Author: Kedar
  # * Date: 24/01/2018
  # * Reviewed By:
  #
  # @return [Boolean]
  #
  def approval_done?
    @approval_done
  end

end
