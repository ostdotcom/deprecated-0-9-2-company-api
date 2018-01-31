module ClientUsersManagement

  class EditUser < ServicesBase

    # Initialize
    #
    # * Author: Pankaj
    # * Date: 29/01/2018
    # * Reviewed By:
    #
    # @param [Integer] client_user_id (mandatory) - Client User Id to edit that record.
    # @param [Integer] client_id (mandatory) - Client Id to check that its user.
    # @param [String] name (optional) - User name is optional for edit.
    #
    #
    # @return [ClientUsersManagement::EditUser]
    #
    def initialize(params)
      super

      @client_user_id = params[:client_user_id]
      @client_id = params[:client_id].to_i
      @user_name = params[:name]
    end

    # Perform
    #
    # * Author: Pankaj
    # * Date: 29/01/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def perform

      r = validate_client
      return r unless r.success?

      if @user_name.present?
        @client_user.name = @user_name
      end
      @client_user.save

      success

    end

    private

    # Validate Input client
    #
    # * Author: Pankaj
    # * Date: 29/01/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    # Sets @client_user
    def validate_client
      r = validate
      return r unless r.success?

      @client_user = ClientUser.where(id: @client_user_id).first
      return error_with_data('cum_eu_1',
                             "Invalid client.",
                             'Something Went Wrong.',
                             GlobalConstant::ErrorAction.mandatory_params_missing,
                             {}) if @client_user.blank? || @client_user.client_id != @client_id

      success

    end

  end

end
