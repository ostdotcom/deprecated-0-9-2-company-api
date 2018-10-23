module UserManagement

  class Logout < ServicesBase

    # Initialize
    #
    # * Author: Alpesh
    # * Date: 15/01/2018
    # * Reviewed By:
    #
    # @param [String] email (mandatory) - the email of the user which is to be signed up
    # @param [String] password (mandatory) - user password
    # @params [String] browser_user_agent (mandatory) - browser user agent
    #
    # @return [UserManagement::Login]
    #
    def initialize(params)
      super

      @cookie_value = @params[:cookie_value]
      @browser_user_agent = @params[:browser_user_agent]

    end

    # Perform
    #
    # * Author: Alpesh
    # * Date: 15/01/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def perform

      r = validate
      return r unless r.success?

      mark_user_logged_out

    end

    private

    # mark user logged out
    #
    # * Author: Anagha
    # * Date: 23/10/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def mark_user_logged_out

      service_response = UserManagement::VerifyCookie.new(
        cookie_value: @cookie_value,
        browser_user_agent: @browser_user_agent
      ).perform

      if service_response.success?
        User.where(["id = ?", service_response.data[:user_id]]).update_all(["last_logged_in_at = ?", nil])
        CacheManagement::User.new([service_response.data[:user_id]]).clear
      end

      success
    end

  end

end