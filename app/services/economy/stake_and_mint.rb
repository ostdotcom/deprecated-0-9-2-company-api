module Economy

  class StakeAndMint < ServicesBase

    # Initialize
    #
    # * Author: Kedar
    # * Date: 24/01/2018
    # * Reviewed By:
    #
    # @param [Integer] client_id (mandatory) - client id
    # @param [String] token_name (mandatory) - token name
    # @param [String] beneficiary (mandatory) - eth address of the beneficiary
    # @param [Number] to_stake_amount (mandatory) - this is the amount of OST to stake
    #
    # @return [Economy::StakeAndMint]
    #
    def initialize(params)

      super

      @client_id = @params[:client_id]
      @token_name = @params[:token_name]
      @beneficiary = @params[:beneficiary]
      @to_stake_amount = @params[:to_stake_amount]

      @client_token = nil

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
    # Sets @client_token
    #
    # @return [Result::Base]
    #
    def validate_and_sanitize

      r = validate
      return r unless r.success?

      # sanitize
      @token_name = @token_name.to_s.strip

      @client_token = ClientToken.where(
        name: @token_name,
        client_id: @client_id,
        status: GlobalConstant::ClientToken.active_status
      ).first

      return error_with_data(
        'e_sam_1',
        'Token not found.',
        'Token not found.',
        GlobalConstant::ErrorAction.default,
        {}
      ) unless @client_token.present?

      return error_with_data(
        'e_sam_2',
        'Economy not planned.',
        'Economy not planned.',
        GlobalConstant::ErrorAction.default,
        {}
      ) unless @client_token.conversion_rate.to_f > 0

      # if propose was started but registeration not done yet we can not proceed
      if @client_token.send("#{GlobalConstant::ClientToken.propose_initiated_setup_step}?") &&
          !@client_token.registration_done?

        return error_with_data(
            'e_sam_3',
            'Propose was initiated but was not completed.',
            'Propose was initiated but was not completed.',
            GlobalConstant::ErrorAction.default,
            {}
        )

      end

      success

    end

    # Enqueue job
    #
    # * Author: Kedar
    # * Date: 24/01/2018
    # * Reviewed By:
    #
    def enqueue_job

      stake_params = {
          beneficiary: @beneficiary,
          to_stake_amount: @to_stake_amount
      }

      # Registration was already complete, we would directly start staking process
      if @client_token.registration_done?
        stake_params[:uuid] = @client_token.uuid
        BgJob.enqueue(
            Stake::ApproveJob,
            {
                stake_params: stake_params
            }
        )
      # start registration process for client
      else
        BgJob.enqueue(
            ProposeBtJob,
            {
                client_id: @client_id,
                token_symbol: @client_token.symbol,
                token_name: @client_token.name,
                token_conversion_rate: @client_token.conversion_rate,
                stake_params: stake_params
            }
        )
      end

    end

  end

end
