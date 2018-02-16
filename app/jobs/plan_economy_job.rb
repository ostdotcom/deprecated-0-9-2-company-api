class PlanEconomyJob < ApplicationJob

  queue_as GlobalConstant::Sidekiq.queue_name :default_medium_priority_queue

  # Perform
  #
  # * Author: Puneet
  # * Date: 02/02/2018
  # * Reviewed By:
  #
  # @param [Hash] client_token_id (mandatory) - client token id
  #
  def perform(params)

    init_params(params)

    sync_data_in_saas

    generate_dummy_users

    notify_devs

  end

  # init params
  #
  # * Author: Puneet
  # * Date: 02/02/2018
  # * Reviewed By:
  #
  # @param [Hash] params
  #
  def init_params(params)
    @client_token_id = params[:client_token_id].to_i
    @is_first_time_set = params[:is_first_time_set]
    @client_token = CacheManagement::ClientToken.new([@client_token_id]).fetch[@client_token_id]
    @client_token_planner_details = CacheManagement::ClientTokenPlanner.new([@client_token_id]).fetch[@client_token_id]
    @failed_logs = {}
  end

  # Sync changes in Saas DB
  #
  # * Author: Puneet
  # * Date: 02/02/2018
  # * Reviewed By:
  #
  def sync_data_in_saas

    r = SaasApi::OnBoarding::EditBt.new.perform(
        name: @client_token[:name],
        symbol: @client_token[:symbol],
        symbol_icon: @client_token[:symbol_icon],
        conversion_rate: @client_token[:conversion_rate],
        client_id: @client_token[:client_id]
    )

    unless r.success?
      puts "error in sync_data_in_saas: #{r.to_json}"
      @failed_logs[:data_sync_in_saas] = r.to_json
    end

  end

  #
  # * Author: Puneet
  # * Date: 02/02/2018
  # * Reviewed By:
  #
  def generate_dummy_users

    return unless @is_first_time_set

    r = SaasApi::OnBoarding::CreateDummyUsers.new.perform(
      client_id: @client_id,
      number_of_users: @client_token_planner_details[:initial_no_of_users] || 25
    )

    unless r.success?
      puts "error in generate_dummy_users: #{r.to_json}"
      @failed_logs[:generate_dummy_users] = r.to_json
    end

  end

  # Send mail
  #
  # * Author: Puneet
  # * Date: 02/02/2018
  # * Reviewed By:
  #
  def notify_devs
    ApplicationMailer.notify(
        data: @failed_logs,
        body: {client_token_id: @client_token_id},
        subject: 'Exception in PlanEconomyJob'
    ).deliver if @failed_logs.present?
  end

end
