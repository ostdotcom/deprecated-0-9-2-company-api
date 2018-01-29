class Stake::StartJob < ApplicationJob

  include Util::ResultHelper

  queue_as GlobalConstant::Sidekiq.queue_name :default_medium_priority_queue

  # Perform
  #
  # * Author: Kedar
  # * Date: 29/01/2018
  # * Reviewed By:
  #
  # @param [String] beneficiary (mandatory) - eth address of the beneficiary
  # @param [Number] to_stake_amount (mandatory) - this is the amount of OST to stake
  # @param [String] uuid (mandatory) - uuid of the token
  #
  def perform(params)

    init_params(params)

    r = start_stake
    return unless r.success?

    Rails.logger.info("staking started with transaction hash:: #{@transaction_hash}")

  end

  private

  # init params
  #
  # * Author: Kedar
  # * Date: 24/01/2018
  # * Reviewed By:
  #
  # @param [Hash] params
  #
  def init_params(params)
    @beneficiary = params[:beneficiary]
    @to_stake_amount = params[:to_stake_amount]
    @uuid = params[:uuid]

    @transaction_hash = nil
  end

  # Start stake
  #
  # * Author: Kedar
  # * Date: 24/01/2018
  # * Reviewed By:
  #
  # @return [Result::Base]
  #
  def start_stake
    params = {
      beneficiary: @beneficiary,
      to_stake_amount: @to_stake_amount,
      uuid: @uuid
    }

    r = SaasApi::Stake::Start.new.perform(params)
    return r unless r.success?

    @transaction_hash =  r.data[:transaction_hash]

    Rails.logger.info "Stake transaction hash:: " + @transaction_hash

    success
  end

end
