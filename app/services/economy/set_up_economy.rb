module Economy

  class SetUpEconomy < ServicesBase

    # Initialize
    #
    # * Author: Puneet
    # * Date: 24/01/2018
    # * Reviewed By:
    #
    # @params [Integer] client_token_id (mandatory) - client token id
    # @params [Decimal] conversion_factor (mandatory) - how many branded tokens are there in one OST
    # @params [Integer] airdrop_bt_per_user (mandatory) - how many BT are to given to each user
    # @params [Integer] initial_number_of_users (mandatory) - init number of users
    #
    # @return [Economy::SetUpEconomy]
    #
    def initialize(params)

      super

      @client_token_id = @params[:client_token_id]
      @conversion_factor = @params[:conversion_factor]
      @initial_number_of_users = @params[:initial_number_of_users]
      @airdrop_bt_per_user = @params[:airdrop_bt_per_user]

      @client_token = nil
      @client_token_planner = nil
      @is_sync_in_saas_needed = false

    end

    # Perform
    #
    # * Author: Puneet
    # * Date: 24/01/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def perform

      r = validate_and_sanitize
      return r unless r.success?

      r = update_in_mysql
      return r unless r.success?

      r = update_in_saas
      return r unless r.success?

      success_with_data(
        client_token: @client_token,
        client_token_planner: @client_token_planner
      )

    end

    private

    # Validate and sanitize
    #
    # * Author: Puneet
    # * Date: 24/01/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def validate_and_sanitize

      r = validate
      return r unless r.success?

      @conversion_factor = BigDecimal.new(@conversion_factor)

      return error_with_data(
          'e_sup_1',
          'Conversion should be greater than 0.',
          'Conversion should be greater than 0.',
          GlobalConstant::ErrorAction.default,
          {}
      ) if @conversion_factor <= 0

      @initial_number_of_users = @initial_number_of_users.to_i

      return error_with_data(
          'e_sup_2',
          'Initial number of users should be greater than 0.',
          'Initial number of users should be greater than 0.',
          GlobalConstant::ErrorAction.default,
          {}
      ) if @initial_number_of_users <= 0

      @airdrop_bt_per_user = @airdrop_bt_per_user.to_i

      return error_with_data(
          'e_sup_3',
          'Airdrop branded token per user should be greater than 0.',
          'Airdrop branded token per user should be greater than 0.',
          GlobalConstant::ErrorAction.default,
          {}
      ) if @airdrop_bt_per_user <= 0

      success

    end

    # update
    #
    # * Author: Puneet
    # * Date: 24/01/2018
    # * Reviewed By:
    #
    # Sets @
    #
    # @return [Result::Base]
    #
    def update_in_mysql

      @client_token = ClientToken.where(
          id: @client_token_id,
          status: GlobalConstant::ClientToken.active_status
      ).first

      return error_with_data(
          'e_sup_4',
          'No token found.',
          'No token found.',
          GlobalConstant::ErrorAction.default,
          {}
      ) unless @client_token.present?

      if @client_token.registration_done? && @client_token.conversion_factor != @conversion_factor
        return error_with_data(
            'e_sup_5',
            'Conversion Rate Can Not be changed after Registering BT.',
            'Conversion Rate Can Not be changed after Registering BT.',
            GlobalConstant::ErrorAction.default,
            {}
        )
      end

      @client_token.conversion_factor = @conversion_factor

      if @client_token.changed?
        @is_sync_in_saas_needed = true
        @client_token.save!
        CacheManagement::ClientToken.new([@client_token.id]).clear
      end

      @client_token_planner = ClientTokenPlanner.find_or_initialize_by(client_token_id: @client_token_id)
      @client_token_planner.initial_no_of_users = @initial_number_of_users
      @client_token_planner.initial_airdrop_in_wei = Util::Converter.to_wei_value(@airdrop_bt_per_user)

      if @client_token_planner.changed?
        @client_token_planner.save!
        CacheManagement::ClientTokenPlanner.new([@client_token.id]).clear
      end

      success

    end

    # Enqueue job on first time economy setup
    #
    # * Author: Puneet
    # * Date: 02/02/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def update_in_saas

      return success unless @is_sync_in_saas_needed

      SaasApi::OnBoarding::EditBt.new.perform(
          name: @client_token[:name],
          symbol: @client_token[:symbol],
          conversion_factor: @conversion_factor,
          client_id: @client_token[:client_id]
      )

      success

    end

  end

end
