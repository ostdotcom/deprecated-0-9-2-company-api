module Economy

  class Plan < ServicesBase

    # Initialize
    #
    # * Author: Kedar
    # * Date: 24/01/2018
    # * Reviewed By:
    #
    # @params [Integer] client_token_id (mandatory) - client token id
    # @params [Decimal] conversion_rate (mandatory) - how many branded tokens are there in one OST
    # @params [Decimal] token_worth_in_usd (mandatory) - approx worth of BT in USD
    # @params [Integer] airdrop_bt_per_user (mandatory) - how many BT are to given to each user
    # @params [Integer] initial_number_of_users (optional) - init number of users
    #
    #
    # @return [Economy::Plan]
    #
    def initialize(params)

      super

      @client_token_id = @params[:client_token_id]
      @token_worth_in_usd = @params[:token_worth_in_usd]

      # Optional params
      @conversion_rate = @params[:conversion_rate]
      @initial_number_of_users = @params[:initial_number_of_users]
      @airdrop_bt_per_user = @params[:airdrop_bt_per_user]

      @is_first_time_set = false
      @is_sync_in_saas_needed = false

    end

    # Perform
    #
    # * Author: Kedar
    # * Date: 24/01/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def perform

      r = validate_and_sanitize
      return r unless r.success?

      r = update
      return r unless r.success?

      enqueue_job

      success

    end

    private

    # Validate and sanitize
    #
    # * Author: Kedar
    # * Date: 24/01/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def validate_and_sanitize

      r = validate
      return r unless r.success?

      if @conversion_rate.present?

        @conversion_rate = @conversion_rate.to_f

        return error_with_data(
            'e_p_1',
            'Conversion should be greater than 0.',
            'Conversion should be greater than 0.',
            GlobalConstant::ErrorAction.default,
            {}
        ) if @conversion_rate <= 0

      end

      if @initial_number_of_users.present?

        @initial_number_of_users = @initial_number_of_users.to_i

        return error_with_data(
            'e_p_2',
            'Initial number of users should be greater than 0.',
            'Initial number of users should be greater than 0.',
            GlobalConstant::ErrorAction.default,
            {}
        ) if @initial_number_of_users <= 0

      end

      if @airdrop_bt_per_user.present?

        @airdrop_bt_per_user = @airdrop_bt_per_user.to_i

        return error_with_data(
            'e_p_3',
            'Airdrop branded token per user should be greater than 0.',
            'Airdrop branded token per user should be greater than 0.',
            GlobalConstant::ErrorAction.default,
            {}
        ) if @airdrop_bt_per_user <= 0

      end

      success

    end

    # update
    #
    # * Author: Kedar
    # * Date: 24/01/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def update

      ct = ClientToken.where(
        id: @client_token_id,
        status: GlobalConstant::ClientToken.active_status
      ).first

      return error_with_data(
        'e_p_4',
        'No token found.',
        'No token found.',
        GlobalConstant::ErrorAction.default,
        {}
      ) unless ct.present?

      if ct.registration_done? && ct.conversion_rate != @conversion_rate
        return error_with_data(
            'e_p_5',
            'Conversion Rate Can Not be changed after Registering BT.',
            'Conversion Rate Can Not be changed after Registering BT.',
            GlobalConstant::ErrorAction.default,
            {}
        )
      end

      ct.conversion_rate = @conversion_rate if @conversion_rate.present?

      ctp = ClientTokenPlanner.find_or_initialize_by(client_token_id: @client_token_id)
      ctp.initial_no_of_users = @initial_number_of_users if @initial_number_of_users.present?
      ctp.initial_airdrop_in_wei = Util::Converter.to_wei_value(@airdrop_bt_per_user) if @airdrop_bt_per_user.present?
      ctp.token_worth_in_usd = @token_worth_in_usd if @token_worth_in_usd.present?

      if ctp.changed?

        ctp.save!
        CacheManagement::ClientTokenPlanner.new([ct.id]).clear

        if ctp.token_worth_in_usd_changed? && !ct.send("#{GlobalConstant::ClientToken.token_worth_in_usd_setup_step}?")

          bit_value = ClientToken.setup_steps_config[GlobalConstant::ClientToken.token_worth_in_usd_setup_step]

          # We are firing this extra update query to ensure that even
          # if multiple requests are fired from FE, we enqueue job onlu once
          updated_row_cnt = ClientToken.where(id: @client_token_id).
              where("setup_steps is NULL OR (setup_steps & #{bit_value} = 0)").update_all("setup_steps = setup_steps | #{bit_value}")

          @is_first_time_set = updated_row_cnt == 1

        end

      end

      if ct.changed?
        @is_sync_in_saas_needed = true
        ct.save!
        CacheManagement::ClientToken.new([ct.id]).clear
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
    def enqueue_job

      BgJob.enqueue(
        PlanEconomyJob,
        {
            client_token_id: @client_token_id,
            is_first_time_set: @is_first_time_set,
            is_sync_in_saas_needed: @is_sync_in_saas_needed
        }
      )

    end

  end

end
