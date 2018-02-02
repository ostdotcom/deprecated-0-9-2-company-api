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
    #
    # @return [Economy::Plan]
    #
    def initialize(params)

      super

      @client_token_id = @params[:client_token_id]
      @conversion_rate = @params[:conversion_rate]
      @initial_number_of_users = @params[:initial_number_of_users]
      @airdrop_bt_per_user = @params[:airdrop_bt_per_user]

      @is_first_time_set = nil

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

      # sanitize
      @token_name = @token_name.to_s.strip

      @conversion_rate = @conversion_rate.to_f

      return error_with_data(
        'e_p_1',
        'Conversion should be greater than 0.',
        'Conversion should be greater than 0.',
        GlobalConstant::ErrorAction.default,
        {}
      ) if @conversion_rate <= 0

      @initial_number_of_users = @initial_number_of_users.to_i

      return error_with_data(
        'e_p_2',
        'Initial number of users should be greater than 0.',
        'Initial number of users should be greater than 0.',
        GlobalConstant::ErrorAction.default,
        {}
      ) if @initial_number_of_users <= 0


      @airdrop_bt_per_user = @airdrop_bt_per_user.to_f

      return error_with_data(
        'e_p_3',
        'Airdrop branded token per user should be greater than 0.',
        'Airdrop branded token per user should be greater than 0.',
        GlobalConstant::ErrorAction.default,
        {}
      ) if @airdrop_bt_per_user <= 0

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

      ct.conversion_rate = @conversion_rate
      ct.initial_number_of_users = @initial_number_of_users
      ct.airdrop_bt_per_user = @airdrop_bt_per_user

      @is_first_time_set = !ct.send("#{GlobalConstant::ClientToken.set_conversion_rate_setup_step}?")

      ct.send("set_#{GlobalConstant::ClientToken.set_conversion_rate_setup_step}")

      ct.save!

      Cache::ClientToken.new([ct.id]).clear

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

      return unless @is_first_time_set

      BgJob.enqueue(
        PlanEconomyJob,
        {client_token_id: @client_token_id}
      )

    end

  end

end
