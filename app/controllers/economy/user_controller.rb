class Economy::UserController < Economy::BaseController

  # Create user for client
  #
  # * Author: Pankaj
  # * Date: 30/01/2018
  # * Reviewed By:
  #
  def create_user

    result = ClientManagement::GetClientApiCredentials.new(client_id: params[:client_id]).perform
    render_api_response(result) unless result.success?

    # Create OST Sdk Obj
    credentials = OSTSdk::Util::APICredentials.new(result.data[:api_key], result.data[:api_secret])
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

    service_response = ClientUsersManagement::EditUser.new(params).perform

    render_api_response(service_response)

  end

  # list all users of client
  #
  # * Author: Puneet
  # * Date: 02/02/2018
  # * Reviewed By:
  #
  def list_users

    service_response = ClientUsersManagement::ListUser.new(params).perform

    render_api_response(service_response)

  end

end
