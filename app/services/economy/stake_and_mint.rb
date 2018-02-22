module Economy

  class StakeAndMint < ServicesBase

    # Initialize
    #
    # * Author: Kedar
    # * Date: 24/01/2018
    # * Reviewed By: Sunil
    #
    # @param [Integer] client_id (mandatory) - client id
    # @param [Integer] user_id (mandatory) - user id
    # @params [Integer] client_token_id (mandatory) - client token id
    # @param [Decimal] bt_to_mint (mandatory) - BT amount to stake and mint
    # @param [Decimal] st_prime_to_mint (mandatory) - ST' amount to stake and mint
    # @param [String] transaction_hash (mandatory) - transaction hash of the initial transfer to the staker.
    #
    # @return [Economy::StakeAndMint]
    #
    def initialize(params)

      super

      @user_id = @params[:user_id]
      @client_id = @params[:client_id]
      @client_token_id = @params[:client_token_id]
      @bt_to_mint = @params[:bt_to_mint]
      @st_prime_to_mint = @params[:st_prime_to_mint]
      @transaction_hash = @params[:transaction_hash]

      @user = nil
      @client_token = nil
      @stake_and_mint_init_chain_id = nil

    end

    # Perform
    #
    # * Author: Kedar
    # * Date: 24/01/2018
    # * Reviewed By: Sunil
    #
    # @return [Result::Base]
    #
    def perform

      r = validate_and_sanitize
      return r unless r.success?

      enqueue_propose_job

      r = enqueue_stake_and_mint_job
      return r unless r.success?

      success_with_data(
        stake_and_mint_init_chain_id: @stake_and_mint_init_chain_id.to_i
      )

    end

    private

    # Validate and sanitize
    #
    # * Author: Kedar
    # * Date: 24/01/2018
    # * Reviewed By: Sunil
    #
    # Sets @client_token
    #
    # @return [Result::Base]
    #
    def validate_and_sanitize

      r = validate
      return r unless r.success?

      return error_with_data(
        'e_sam_1',
        'Invalid stake and mint parameters.',
        'Invalid stake and mint parameters.',
        GlobalConstant::ErrorAction.default,
        {}
      ) if @bt_to_mint.to_f < 0 || @st_prime_to_mint.to_f < 0 || @transaction_hash.blank?

      r = validate_user
      return r unless r.success?

      r = validate_client
      return r unless r.success?

      r = validate_client_token
      return r unless r.success?

      success

    end

    # Validate User
    #
    # * Author: Puneet
    # * Date: 29/01/2018
    # * Reviewed By: Sunil
    #
    # Sets @user
    #
    # @return [Result::Base]
    #
    def validate_user

      cache_data = CacheManagement::User.new([@user_id]).fetch
      @user = cache_data[@user_id]

      return error_with_data(
          'e_sam_2',
          'Invalid User Id',
          'Invalid User Id',
          GlobalConstant::ErrorAction.default,
          {}
      ) if @user.blank?

      return error_with_data(
          'e_sam_3',
          'User Not Verified',
          'User Not Verified',
          GlobalConstant::ErrorAction.default,
          {}
      ) if @user[:properties].exclude?(GlobalConstant::User.is_user_verified_property)

      success

    end


    # Validate Client
    #
    # * Author: Puneet
    # * Date: 29/01/2018
    # * Reviewed By: Sunil
    #
    # Sets @client
    #
    # @return [Result::Base]
    #
    def validate_client
      @client = CacheManagement::Client.new([@client_id]).fetch[@client_id]
      return error_with_data(
        'pbj_',
        'Invalid Client.',
        'Invalid Client.',
        GlobalConstant::ErrorAction.default,
        {}
      ) if @client.blank? || @client[:status] != GlobalConstant::Client.active_status

      success
    end

    # Validate Client Token
    #
    # * Author: Puneet
    # * Date: 29/01/2018
    # * Reviewed By: Sunil
    #
    # Sets @client_token
    #
    # @return [Result::Base]
    #
    def validate_client_token
      @client_token = ClientToken.where(
        id: @client_token_id
      ).first

      return error_with_data(
        'e_sam_4',
        'Token not found.',
        'Token not found.',
        GlobalConstant::ErrorAction.default,
        {}
      ) if @client_token.blank? || @client_token.status != GlobalConstant::ClientToken.active_status

      return error_with_data(
        'e_sam_5',
        'Economy not planned.',
        'Economy not planned.',
        GlobalConstant::ErrorAction.default,
        {}
      ) if @client_token.conversion_rate.to_f <= 0 || @client_token.name.blank? ||
        @client_token.symbol.blank? || @client_token.reserve_uuid.blank?

      # if propose was started but registeration not done yet we can not proceed
      if @client_token.propose_initiated? && !@client_token.registration_done?
        return error_with_data(
          'e_sam_6',
          'Propose was initiated but was not completed.',
          'Propose was initiated but was not completed.',
          GlobalConstant::ErrorAction.default,
          {}
        )
      end

      success
    end

    # Enqueue propose branded token job
    #
    # * Author: Puneet
    # * Date: 29/01/2018
    # * Reviewed By: Sunil
    #
    # Sets @stake_and_mint_init_chain_id, @propose_critical_log_obj
    # Updates @client_token
    #
    # @return [Result::Base]
    #
    def enqueue_propose_job

      return if @client_token.propose_initiated? || @client_token.registration_done?

      @propose_critical_log_obj = CriticalChainInteractionLog.create!(
        {
          client_id: @client_id,
          client_token_id: @client_token_id,
          activity_type: GlobalConstant::CriticalChainInteractions.propose_bt_activity_type,
          chain_type: GlobalConstant::CriticalChainInteractions.utility_chain_type,
          request_params: {
            token_symbol: @client_token.symbol,
            token_name: @client_token.name,
            token_conversion_rate: @client_token.conversion_rate.to_f
          },
          status: GlobalConstant::CriticalChainInteractions.queued_status
        }
      )

      @stake_and_mint_init_chain_id ||= @propose_critical_log_obj.id

      @client_token.send("set_#{GlobalConstant::ClientToken.propose_initiated_setup_step}")
      @client_token.save!

      BgJob.enqueue(
        ::ProposeBrandedToken::StartProposeJob,
        {
          critical_log_id: @propose_critical_log_obj.id,
          parent_id: @stake_and_mint_init_chain_id
        }
      )
    end

    # Enqueue stake and mint job
    #
    # * Author: Puneet
    # * Date: 29/01/2018
    # * Reviewed By: Sunil
    #
    # Sets @user
    #
    # @return [Result::Base]
    #
    def enqueue_stake_and_mint_job

      return if @bt_to_mint.to_f <= 0 && @st_prime_to_mint.to_f <= 0

      critical_log_obj = nil

      begin

        critical_log_obj = CriticalChainInteractionLog.create!(
            {
                parent_id: @stake_and_mint_init_chain_id,
                client_id: @client_id,
                client_token_id: @client_token_id,
                activity_type: GlobalConstant::CriticalChainInteractions.staker_initial_transfer_activity_type,
                chain_type: GlobalConstant::CriticalChainInteractions.value_chain_type,
                transaction_hash: @transaction_hash,
                request_params: {
                    bt_to_mint: @bt_to_mint,
                    st_prime_to_mint: @st_prime_to_mint
                },
                status: GlobalConstant::CriticalChainInteractions.queued_status
            }
        )

      rescue ActiveRecord::RecordNotUnique => e

        r = error_with_data(
            'e_sam_7',
            "Duplicate Tx Hash : #{@transaction_hash}",
            "Duplicate Tx Hash : #{@transaction_hash}",
            GlobalConstant::ErrorAction.default,
            {}
        )

        return r

      end

      @stake_and_mint_init_chain_id ||= critical_log_obj.id

      BgJob.enqueue(
        ::StakeAndMint::GetTransferToStakerStatusJob,
        {
          critical_log_id: critical_log_obj.id,
          parent_id: @stake_and_mint_init_chain_id
        }
      )

      success

    end

  end

end
