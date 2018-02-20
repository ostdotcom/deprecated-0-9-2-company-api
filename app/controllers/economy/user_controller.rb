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
        error_with_data(
            'uc_cu_1',
            "Invalid client.",
            'Something Went Wrong.',
            GlobalConstant::ErrorAction.default,
            {}
        )
    ) if result.blank?

    # Create OST Sdk Obj
    credentials = OSTSdk::Util::APICredentials.new(result[:api_key], result[:api_secret])
    @ost_sdk_obj = OSTSdk::Saas::Users.new(GlobalConstant::Base.sub_env, credentials)
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
        error_with_data(
            'uc_cu_1',
            "Invalid client.",
            'Something Went Wrong.',
            GlobalConstant::ErrorAction.default,
            {}
        )
    ) if result.blank?

    # Create OST Sdk Obj
    credentials = OSTSdk::Util::APICredentials.new(result[:api_key], result[:api_secret])
    @ost_sdk_obj = OSTSdk::Saas::Users.new(GlobalConstant::Base.sub_env, credentials)
    service_response = @ost_sdk_obj.edit({name: params[:name], address_uuid: params[:address_uuid]})

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

end
