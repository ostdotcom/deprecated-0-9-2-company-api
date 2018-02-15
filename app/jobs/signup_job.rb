class SignupJob < ApplicationJob

  include Util::ResultHelper

  queue_as GlobalConstant::Sidekiq.queue_name :default_medium_priority_queue

  # Perform
  #
  # * Author: Pankaj
  # * Date: 14/02/2018
  # * Reviewed By:
  #
  # @param [Integer] user_id (mandatory) - User Id which has signed up
  # @param [Integer] client_id (mandatory) - Client Id with which user has been associated.
  # @param [Integer] client_token_id (mandatory) - Client Token Id with which user has signed up with.
  # @param [Integer] client_api_needed (mandatory) - Client Api credentials needs to be created or not
  #
  def perform(params)

    init_params(params)

    r = validate
    unless r.success?
      notify_devs(r)
      return r
    end

    create_client_api_credentials

    create_user_email_service_api_call_hook

    send_double_optin_link

    r = setup_token_on_saas

    if r.success?
      @client_token.reserve_uuid = r.data['reserveUuid']
      @client_token.save
    end

  end

  private

  # init params
  #
  # * Author: Pankaj
  # * Date: 14/02/2018
  # * Reviewed By:
  #
  # @param [Hash] params
  #
  def init_params(params)
    @params = params

    @user_id = params[:user_id]
    @client_id = params[:client_id]
    @client_api_needed = params[:client_api_needed]
    @client_token_id = params[:client_token_id]
    @client_token = nil
  end

  # Validate User
  #
  # * Author: Pankaj
  # * Date: 14/02/2018
  # * Reviewed By:
  #
  # Sets @user, @client_token
  #
  # @return [Result]
  #
  def validate
    @user = User.where(id: @user_id).first
    return error_with_data("j_sj_1", "Invalid user", "Invalid user",
                           "", {}, {}) if @user.blank?

    return error_with_data("j_sj_2", "Invalid client", "Invalid client",
                           "", {}, {}) if @user.default_client_id != @client_id

    @client_token = ClientToken.where(id: @client_token_id).first
    return error_with_data("j_sj_3", "Invalid client Token", "Invalid client Token",
                           "", {}, {}) if @client_token.client_id != @client_id

    success

  end

  # Generate Client Api Credentials
  #
  #
  # * Author: Pankaj
  # * Date: 14/02/2018
  # * Reviewed By:
  #
  # @return [Boolean]
  #
  def create_client_api_credentials
    return unless @client_api_needed

    result = generate_api_key_salt
    return unless result.success?

    api_salt = result.data

    api_credential = ClientApiCredential.new(
      client_id: @client_id,
      api_key: ClientApiCredential.generate_random_app_id,
      api_secret: ClientApiCredential.generate_encrypted_secret_key(api_salt[:plaintext]),
      api_salt: api_salt[:ciphertext_blob],
      expiry_timestamp: (Time.now+10.year).to_i
    )

    api_credential.save!

  end

  # Generate Api Key salt
  #
  # * Author: Pankaj
  # * Date: 14/02/2018
  # * Reviewed By:
  #
  # @return [Result::Base]
  #
  def generate_api_key_salt
    Aws::Kms.new('info', 'user').generate_data_key
  end

  # Create Hook to sync data in Email Service
  #
  # * Author: Pankaj
  # * Date: 14/02/2018
  # * Reviewed By:
  #
  def create_user_email_service_api_call_hook

    Email::HookCreator::AddContact.new(
        email: @user.email,
        custom_attributes: {
            GlobalConstant::PepoCampaigns.user_registered_attribute => GlobalConstant::PepoCampaigns.user_registered_value
        }
    ).perform

  end


  # Send Double Opt In Link to user
  #
  # * Author: Pankaj
  # * Date: 14/02/2018
  # * Reviewed By:
  #
  def send_double_optin_link
    r = UserManagement::SendDoubleOptInLink.new(email: @user.email).perform
    notify_devs(r) unless r.success?
  end

  # Send SetUp Token On Saas
  #
  # * Author: Pankaj
  # * Date: 14/02/2018
  # * Reviewed By:
  #
  # @return [Result::Base]
  #
  def setup_token_on_saas
    r = SaasApi::OnBoarding::SetupBt.new.perform(
        symbol: @client_token.symbol, name: @client_token.name,
        client_id: @client_id
    )
    notify_devs(r) unless r.success?
    r
  end

  # Notify devs about error
  #
  # * Author: Pankaj
  # * Date: 14/02/2018
  # * Reviewed By:
  #
  def notify_devs(error)
    ApplicationMailer.notify(
        body: {error: error, input_params: @params},
        data: {},
        subject: "Error in SignUp Job"
    ).deliver
  end

end
