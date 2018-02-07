module ClientUsersManagement

  class ListUser < ServicesBase

    # Initialize
    #
    # * Author: Puneet
    # * Date: 02/02/2018
    # * Reviewed By:
    #
    # @param [Integer] user_id (mandatory) - user Id
    # @param [Integer] client_id (mandatory) - Client Id
    # @param [Integer] client_token_id (mandatory) - Client Token Id
    # @param [Integer] page_no (optional) - page no
    # @param [String] filter (optional) - newly_added
    #
    # @return [ClientUsersManagement::ListUser]
    #
    def initialize(params)

      super

      @client_id = @params[:client_id]
      @client_token_id = @params[:client_token_id]
      @user_id = @params[:user_id]
      @page_no = @params[:page_no]
      @filter = @params[:filter]

      @page_size = 25
      @client = nil
      @client_token = nil
      @economy_users = []
      @has_more = false

    end

    # Perform
    #
    # * Author: Puneet
    # * Date: 02/02/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def perform

      r = validate_and_sanitize
      return r unless r.success?

      r = fetch_users
      return r unless r.success?

      success_with_data(api_response)

    end

    private

    # Validate and sanitize
    #
    # * Author: Puneet
    # * Date: 02/02/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def validate_and_sanitize

      r = validate
      return r unless r.success?

      r = validate_pagination_params
      return r unless r.success?

      r = validate_client
      return r unless r.success?

      success

    end

    # Validate pagination params
    #
    # * Author: Puneet
    # * Date: 02/02/2018
    # * Reviewed By:
    #
    # Sets @client
    #
    # @return [Result::Base]
    #
    def validate_pagination_params

      if @page_no.present?
        return error_with_data(
            'cum_lu_1',
            "Invalid Page No.",
            "Invalid Page No.",
            GlobalConstant::ErrorAction.mandatory_params_missing,
            {}
        ) unless Util::CommonValidator.is_numeric?(@page_no)
        @page_no = @page_no.to_i
      else
        @page_no = 1
      end

      if @filter.present?
        return error_with_data(
            'cum_lu_1',
            "Invalid Page No.",
            "Invalid Page No.",
            GlobalConstant::ErrorAction.mandatory_params_missing,
            {}
        ) if [newly_added_filter].exclude?(@filter)
      else
        @filter = ''
      end

      success

    end

    # Validate Input client
    #
    # * Author: Puneet
    # * Date: 02/02/2018
    # * Reviewed By:
    #
    # Sets @client, @client_token
    #
    # @return [Result::Base]
    #
    def validate_client

      @client = CacheManagement::Client.new([@client_id]).fetch[@client_id]

      return error_with_data(
          'cum_lu_2',
           "Invalid client.",
           'Something Went Wrong.',
           GlobalConstant::ErrorAction.mandatory_params_missing,
           {}
      ) if @client.blank? || @client[:status] != GlobalConstant::Client.active_status

      @client_id = @client_id.to_i

      @client_token = CacheManagement::ClientToken.new([@client_token_id]).fetch[@client_token_id]

      success

    end

    # Fetch users
    #
    # * Author: Puneet
    # * Date: 02/02/2018
    # * Reviewed By:
    #
    # Sets @economy_users
    #
    # @return [Result::Base]
    #
    def fetch_users

      ar = ClientUser.where(client_id: @client_id)

      case @filter
        when newly_added_filter
          ar = ar.where(total_airdropped_tokens_in_wei: 0)
      end

      offset = (@page_no-1) * @page_size
      economy_users = ar.limit(@page_size+1).offset(offset).all
      @has_more = economy_users[@page_size].present?
      economy_users = economy_users[0...-1] if economy_users.length >= @page_size

      @economy_users = economy_users.map do |object|
        {
          id: object.id,
          name: object.name,
          total_airdropped_tokens_in_wei: object.total_airdropped_tokens_in_wei,
          total_airdropped_tokens: Util::Converter.from_wei_value(object.total_airdropped_tokens_in_wei),
          token_balance_in_wei: 0, #TODO: fix later
          token_balance: Util::Converter.from_wei_value(0) #TODO: fix later
        }
      end

      success

    end

    def result_type
      'economy_users'
    end

    # API response
    #
    # * Author: Puneet
    # * Date: 02/02/2018
    # * Reviewed By:
    #
    # @return [Hash]
    #
    def api_response
      rsp = {
        result_type: result_type,
        result_type.to_sym => @economy_users,
        client_token: @client_token,
        user: CacheManagement::ClientToken.new([@user_id]).fetch[@user_id],
        client_token_balance: FetchClientTokenBalance.new(client_token: @client_token).perform,
        client_ost_balance: FetchClientOstBalance.new(client_id: @client_token[:client_id]).perform
        next_page_payload: @has_more ? {
          page_no: @page_no + 1,
          filter: @filter
        } : {}
      }
    end

    def newly_added_filter
      'newly_added'
    end

  end

end
