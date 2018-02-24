module Economy

  class Plan < ServicesBase

    # Initialize
    #
    # * Author: Kedar
    # * Date: 24/01/2018
    # * Reviewed By:
    #
    # @params [Integer] client_token_id (mandatory) - client token id
    # @params [Decimal] token_worth_in_usd (mandatory) - approx worth of BT in USD
    #
    # @return [Economy::Plan]
    #
    def initialize(params)

      super

      @client_token_id = @params[:client_token_id]
      @token_worth_in_usd = @params[:token_worth_in_usd]

      @is_first_time_set = false

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

      @token_worth_in_usd = BigDecimal.new(@token_worth_in_usd)

      validation_errors = {}
      validation_errors[:token_worth_in_usd] = 'BT To Fiat Value should be > 0' if @token_worth_in_usd <= 0

      max_allowed_token_worth_in_usd = ClientTokenPlanner.max_allowed_token_worth_in_usd
      if @token_worth_in_usd > max_allowed_token_worth_in_usd
        validation_errors[:token_worth_in_usd] = "BT To Fiat Value should be < #{max_allowed_token_worth_in_usd}"
      end

      return error_with_data(
          'um_su_1',
          'Plan Economy Error',
          '',
          GlobalConstant::ErrorAction.default,
          {},
          validation_errors
      ) if validation_errors.present?

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
        'e_p_2',
        'No token found.',
        'No token found.',
        GlobalConstant::ErrorAction.default,
        {}
      ) unless ct.present?

      ctp = ClientTokenPlanner.find_or_initialize_by(client_token_id: @client_token_id)
      ctp.token_worth_in_usd = @token_worth_in_usd

      if ctp.changed?

        if ctp.token_worth_in_usd_changed? && !ct.send("#{GlobalConstant::ClientToken.token_worth_in_usd_setup_step}?")

          bit_value = ClientToken.setup_steps_config[GlobalConstant::ClientToken.token_worth_in_usd_setup_step]

          # We are firing this extra update query to ensure that even
          # if multiple requests are fired from FE, we enqueue job onlu once
          updated_row_cnt = ClientToken.where(id: @client_token_id).
              where("setup_steps is NULL OR (setup_steps & #{bit_value} = 0)").update_all("setup_steps = setup_steps | #{bit_value}")

          @is_first_time_set = (updated_row_cnt == 1)

          CacheManagement::ClientToken.new([ct.id]).clear if @is_first_time_set

        end

        ctp.save!
        CacheManagement::ClientTokenPlanner.new([ct.id]).clear

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
            is_first_time_set: @is_first_time_set
        }
      )

    end

  end

end
