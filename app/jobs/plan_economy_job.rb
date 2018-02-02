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

    r = validate_client_token
    return r unless r.success?

    generate_dummy_transaction_types

    generate_dummy_users

    update_client_token

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
    @client_token_id = params[:client_token_id]
    @client_token = nil
    @failed_logs = {}
  end

  #
  # * Author: Puneet
  # * Date: 02/02/2018
  # * Reviewed By:
  #
  # @return [Result::Base]
  #
  def validate_client_token

    @client_token = ClientToken.where(id: @client_token_id).first

    return error_with_data(
        'grsj_1',
        'Token invalid.',
        'Token not invalid.',
        GlobalConstant::ErrorAction.default,
        {}
    ) if @client_token.blank? || @client_token.send("#{GlobalConstant::ClientToken.configure_transactions_setup_step}?")

    success

  end

  # Generate Dummy types
  #
  # * Author: Puneet
  # * Date: 02/02/2018
  # * Reviewed By:
  #
  # @return [Result::Base]
  #
  def generate_dummy_transaction_types

    failed_logs = {}

    [
      {name: 'Upvote', kind: 'user_to_user', value_currency_type: 'usd', value_in_usd: '0.01', commission_percent: '2'},
      {name: 'Like', kind: 'user_to_user', value_currency_type: 'bt', value_in_bt: '3', commission_percent: '2'},
      {name: 'Rewards', kind: 'company_to_user', value_currency_type: 'bt', value_in_usd: '100', commission_percent: '0'},
      {name: 'Subscription Fees', kind: 'user_to_company', value_currency_type: 'bt', value_in_bt: '10', commission_percent: '0'}
    ].each do |params|

      service_response = Economy::TransactionKind::Create.new(params.merge(client_id: @client_token.client_id)).perform

      failed_logs[params[:name]] = service_response.to_json unless service_response.success?

    end

    @failed_logs[:transaction_types] = failed_logs if failed_logs.present?

  end

  #
  # * Author: Puneet
  # * Date: 02/02/2018
  # * Reviewed By:
  #
  def generate_dummy_users

    result = ClientManagement::GetClientApiCredentials.new(client_id: @client_token[:client_id]).perform
    return result unless result.success?

    # Create OST Sdk Obj
    credentials = OSTSdk::Util::APICredentials.new(result.data[:api_key], result.data[:api_secret])
    @ost_sdk_obj = OSTSdk::Saas::Users.new(GlobalConstant::Base.sub_env, credentials)

    failed_logs = {}

    Array(1..@client_token.initial_number_of_users).each do |id|
      name = "User #{id}"
      service_response = @ost_sdk_obj.create(name: name)
      failed_logs[name] = service_response.to_json unless service_response.success?
    end

    @failed_logs[:dummy_users] = failed_logs if failed_logs.present?

  end

  # Update client token
  #
  # * Author: Kedar
  # * Date: 24/01/2018
  # * Reviewed By:
  #
  # @return [Result::Base]
  #
  def update_client_token
    return if @failed_logs[:transaction_types].present?
    @client_token.send("set_#{GlobalConstant::ClientToken.configure_transactions_setup_step}")
    @client_token.save!
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
