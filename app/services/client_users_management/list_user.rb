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

      return api_response

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
    # Sets @client
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

      @economy_users << {
        id: 1,
        name: 'PK 1',
        total_airdropped_tokens_in_wei: 0,
        total_airdropped_tokens: 0,
        token_balance_in_wei: 0, #TODO: fix later
        token_balance: 0 #TODO: fix later
      }

      @economy_users << {
          id: 2,
          name: 'PK 2',
          total_airdropped_tokens_in_wei: 0,
          total_airdropped_tokens: 0,
          token_balance_in_wei: 0, #TODO: fix later
          token_balance: 0 #TODO: fix later
      }

      @economy_users << {
          id: 3,
          name: 'PK 3',
          total_airdropped_tokens_in_wei: 0,
          total_airdropped_tokens: 0,
          token_balance_in_wei: 0, #TODO: fix later
          token_balance: 0 #TODO: fix later
      }

      @economy_users << {
          id: 4,
          name: 'PK 4',
          total_airdropped_tokens_in_wei: 0,
          total_airdropped_tokens: 0,
          token_balance_in_wei: 0, #TODO: fix later
          token_balance: 0 #TODO: fix later
      }

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
    # @return [Result::Base]
    #
    def api_response

      next_page_payload = @has_more ? {
          page_no: @page_no + 1,
          filter: @filter
      } : {}

      rsp = {
        result_type: result_type,
        result_type.to_sym => @economy_users,
        meta: {
          next_page_payload: next_page_payload
        }
      }

      if @page_no == 1
        r = Util::FetchEconomyCommonEntities.new(user_id: @user_id, client_token_id: @client_token_id).perform
        return r unless r.success?
        rsp.merge!(r.data)
      end

      success_with_data(rsp)

    end

    def newly_added_filter
      'newly_added'
    end

  end

end
