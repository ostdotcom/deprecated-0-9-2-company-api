module Economy

  class StakeAndMint < ServicesBase

    # Initialize
    #
    # * Author: Kedar
    # * Date: 24/01/2018
    # * Reviewed By:
    #
    # @param [Integer] client_id (mandatory) - client id
    # @param [Integer] user_id (mandatory) - user id
    # @params [Integer] client_token_id (mandatory) - client token id
    # @param [Number] to_stake_amount (mandatory) - this is the amount of OST to stake
    # @param [Number] transaction_hash (mandatory) - transaction hash of the transfer to the staker.
    #
    # @return [Economy::StakeAndMint]
    #
    def initialize(params)

      super

      @user_id = @params[:user_id]
      @client_id = @params[:client_id]
      @client_token_id = @params[:client_token_id]
      @to_stake_amount = @params[:to_stake_amount]
      @transaction_hash = @params[:transaction_hash]

      @propose_critical_log_obj = nil

      @user = nil
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

      r = validate_user
      return r unless r.success?

      @client_token = ClientToken.where(
        id: @client_token_id,
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

    # Validate User
    #
    # * Author: Puneet
    # * Date: 29/01/2018
    # * Reviewed By:
    #
    # Sets @user
    #
    # @return [Result::Base]
    #
    def validate_user

      cache_data = CacheManagement::User.new([@user_id]).fetch
      @user = cache_data[@user_id]

      return error_with_data(
          'e_sam_4',
          'Invalid User Id',
          'Invalid User Id',
          GlobalConstant::ErrorAction.default,
          {}
      ) if @user.blank?

      return error_with_data(
          'e_sam_5',
          'User Not Verified',
          'User Not Verified',
          GlobalConstant::ErrorAction.default,
          {}
      ) if @user[:properties].exclude?(GlobalConstant::User.is_user_verified_property)

      success

    end

    def enqueue_propose_job

      return if @client_token.send("#{GlobalConstant::ClientToken.propose_initiated_setup_step}?") ||
        @client_token.registration_done?

      @propose_critical_log_obj = CriticalChainInteractionLog.create!(
        {
          client_id: @client_id,
          client_token_id: @client_token_id,
          activity_type: GlobalConstant::CriticalChainInteractions.propose_initiates_activity_type,
          status: GlobalConstant::CriticalChainInteractions.queued_status
        }
      )

      @client_token.send("set_#{GlobalConstant::ClientToken.propose_initiated_setup_step}")
      @client_token.save!

      BgJob.enqueue(
        ProposeBtJob,
        {
          client_id: @client_id,
          client_token_id: @client_token_id,
          token_symbol: @client_token.symbol,
          token_name: @client_token.name,
          token_conversion_rate: @client_token.conversion_rate,
          critical_log_id: @propose_critical_log_obj.id
        }
      )

    end

    def enqueue_stake_job

      beneficiary = @client_token.get_reserve_address # TODO:: Invalid call

      return error_with_data(
        'e_sam_4',
        'Beneficiary not found.',
        'Beneficiary not found.',
        GlobalConstant::ErrorAction.default,
        {}
      ) unless beneficiary.present?

      parent_propose_critical_log = @propose_critical_log_obj.id if @propose_critical_log_obj.present?
      critical_log_obj = CriticalChainInteractionLog.create!(
        {
          parent_id: parent_propose_critical_log,
          client_id: @client_id,
          client_token_id: @client_token_id,
          activity_type: GlobalConstant::CriticalChainInteractions.staker_initial_transfer_activity_type,
          transaction_hash: @transaction_hash,
          status: GlobalConstant::CriticalChainInteractions.queued_status
        }
      )

      BgJob.enqueue(
        Stake::GetTransferToStakerStatusJob,
        {
          critical_log_id: critical_log_obj.id,
          transaction_hash: @transaction_hash,
          started_job_at: Time.now.to_i,
          stake_params: {
            to_stake_amount: @to_stake_amount,
            uuid: @client_token.uuid,
            beneficiary: beneficiary
          }
        }
      )

    end

  end

end
