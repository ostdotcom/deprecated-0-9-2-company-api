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
