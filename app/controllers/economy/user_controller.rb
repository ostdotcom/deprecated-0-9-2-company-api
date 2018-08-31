class Economy::UserController < Economy::BaseController

  # Create user for client
  #
  # * Author: Pankaj
  # * Date: 30/01/2018
  # * Reviewed By:
  #
  def create_user

    result = CacheManagement::ClientApiCredentials.new([params[:client_id]]).fetch[params[:client_id]]
    render_api_response(
        validation_error(
            'uc_cu_1',
            'invalid_api_params',
            ['invalid_client_id'],
            GlobalConstant::ErrorAction.default
        )
    ) if result.blank?

    # Create OST Sdk Obj
    ost_sdk = OSTSdk::Saas::Services.new(
        api_key: result[:api_key],
        api_secret: result[:api_secret],
        api_base_url: GlobalConstant::SaasApi.v1dot1_base_url,
        api_spec: false
    )

    @ost_sdk_obj = ost_sdk.services.users

    service_response = @ost_sdk_obj.create({name: params[:name]})

    render_api_response(service_response)

  end

  # Edit user of client
  #
  # * Author: Pankaj
  # * Date: 30/01/2018
  # * Reviewed By:
  #
  def edit_user

    result = CacheManagement::ClientApiCredentials.new([params[:client_id]]).fetch[params[:client_id]]
    render_api_response(
        validation_error(
            'uc_cu_2',
            'invalid_api_params',
            ['invalid_client_id'],
            GlobalConstant::ErrorAction.default
        )
    ) if result.blank?

    # Create OST Sdk Obj
    ost_sdk = OSTSdk::Saas::Services.new(
        api_key: result[:api_key],
        api_secret: result[:api_secret],
        api_base_url: GlobalConstant::SaasApi.v1dot1_base_url,
        api_spec: false
    )

    @ost_sdk_obj = ost_sdk.services.users

    service_response = @ost_sdk_obj.edit({name: params[:name], id: params[:address_uuid]})

    render_api_response(service_response)

  end

  # list all users of client
  #
  # * Author: Puneet
  # * Date: 02/02/2018
  # * Reviewed By:
  #
  def list_users

    params[:is_xhr] = request.xhr?.nil? ? 0 : 1
    service_response = ClientUsersManagement::ListUser.new(params).perform

    render_api_response(service_response)

  end

  # AirDrop users of client
  #
  # * Author: Pankaj
  # * Date: 23/02/2018
  # * Reviewed By:
  #
  def airdrop_users

    service_response = Economy::AirdropToUsers.new(params).perform

    render_api_response(service_response)

  end

  # Fetch balances for Address
  #
  # * Author: Santhosh Reddy
  # * Date: 07/08/2018
  # * Reviewed By: Kedar
  #
  def fetch_balances

    service_response = Economy::FetchBalances.new(params).perform

    render_api_response(service_response)

  end

end
