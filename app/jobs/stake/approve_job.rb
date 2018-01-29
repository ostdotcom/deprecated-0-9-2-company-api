class Stake::ApproveJob < ApplicationJob

  include Util::ResultHelper

  queue_as GlobalConstant::Sidekiq.queue_name :default_medium_priority_queue

  # Perform
  #
  # * Author: Kedar
  # * Date: 29/01/2018
  # * Reviewed By:
  #
  # @param [Hash] stake_params (mandatory) - Stake params
  #
  def perform(params)

    init_params(params)

    r = approve
    return unless r.success?

    Rails.logger.info("approve initiated with transaction hash:: #{@transaction_hash}")

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
    @stake_params = params[:stake_params]

    @transaction_hash = nil
  end

  # Approve
  #
  # * Author: Kedar
  # * Date: 24/01/2018
  # * Reviewed By:
  #
  # @return [Result::Base]
  #
  def approve
    r = SaasApi::Stake::Approve.new.perform({})
    return r unless r.success?

    @transaction_hash =  r.data[:transaction_hash]

    success
  end

  # Enqueue job
  #
  # * Author: Kedar
  # * Date: 24/01/2018
  # * Reviewed By:
  #
  def enqueue_job
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
