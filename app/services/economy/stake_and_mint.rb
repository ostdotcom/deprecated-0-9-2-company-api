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
    # @param [Integer] client_token_id (mandatory) - client token id
    # @param [Decimal] bt_to_mint (mandatory) - BT amount to stake and mint
    # @param [Decimal] st_prime_to_mint (mandatory) - ST' amount to stake and mint
    # @param [String] transaction_hash (mandatory) - transaction hash of the initial transfer to the staker.
    #
    # @param [Decimal] ost_to_bt (optional) - OST TO Bt conversion Factor sent by FE
    # @param [Integer] number_of_users (optional) - number_of_users which need to be airdropped
    # @param [String] airdrop_user_list_type (optional) - List type of users who needs to be airdropped
    # @param [Integer] airdrop_amount (optional) - BT amount which needs to be airdropped to users
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

      #optional params
      @ost_to_bt = @params[:ost_to_bt]
      @number_of_users = @params[:number_of_users]
      @airdrop_amount = @params[:airdrop_amount]
      @airdrop_user_list_type = @params[:airdrop_user_list_type]

      @user = nil
      @client_token = nil
      @stake_and_mint_init_chain_id = nil
      @parent_tx_activity_type = nil

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

      r = set_registeration_params_in_db
      return r unless r.success?

      r = enqueue_propose_job
      return r unless r.success?

      r = enqueue_stake_and_mint_job
      return r unless r.success?

      enqueue_airdrop_tokens_job

      #NOTE: Returned this and not fetched from PendingCriticalInteractionIds to avoid extra query
      success_with_data(
        pending_critical_interactions: {
          @parent_tx_activity_type => @stake_and_mint_init_chain_id.to_i
        }
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

      @bt_to_mint = BigDecimal.new(@bt_to_mint)
      @st_prime_to_mint = BigDecimal.new(@st_prime_to_mint)

      return error_with_data(
        'e_sam_1',
        'Invalid stake and mint parameters.',
        'Invalid stake and mint parameters.',
        GlobalConstant::ErrorAction.default,
        {}
      ) if @transaction_hash.blank? || (@bt_to_mint < 0 && @st_prime_to_mint < 0)

      r = validate_user
      return r unless r.success?

      r = validate_client
      return r unless r.success?

      r = validate_client_token
      return r unless r.success?

      r = validate_registeration_params
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
      ) if @client_token.name.blank? || @client_token.symbol.blank? || @client_token.reserve_uuid.blank?

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

      ct_pending_transactions = CacheManagement::PendingCriticalInteractionIds.
          new([@client_token_id]).fetch[@client_token_id]

      if ct_pending_transactions[GlobalConstant::CriticalChainInteractions.propose_bt_activity_type].present? ||
          ct_pending_transactions[GlobalConstant::CriticalChainInteractions.staker_initial_transfer_activity_type].present?

        return error_with_data(
            'e_sam_7',
            'Pending Transaction Is Being Processed. Please try again later.',
            'Pending Transaction Is Being Processed. Please try again later.',
            GlobalConstant::ErrorAction.default,
            {}
        )

      end

      success

    end

    # Validate Registeration Params
    #
    # * Author: Puneet
    # * Date: 29/01/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def validate_registeration_params

      return success if @client_token.propose_initiated? || @client_token.registration_done?

      @airdrop_amount = @airdrop_amount.present? ? BigDecimal.new(@airdrop_amount) : @airdrop_amount
      @ost_to_bt = @ost_to_bt.present? ? BigDecimal.new(@ost_to_bt) : @ost_to_bt
      @number_of_users = @number_of_users.to_i

      return error_with_data(
          'e_sam_8',
          'Invalid registeration parameters.',
          'Invalid registeration parameters.',
          GlobalConstant::ErrorAction.default,
          {}
      ) if @airdrop_amount.blank? || @airdrop_amount < 0 || @ost_to_bt.blank? || @bt_to_mint < 0 || @number_of_users < 0

      success

    end

    # Set Registeration related params in DB
    #
    # * Author: Puneet
    # * Date: 29/01/2018
    # * Reviewed By:
    #
    # Updates @client_token, @client_token_planner
    #
    # @return [Result::Base]
    #
    def set_registeration_params_in_db

      return success if @client_token.propose_initiated? || @client_token.registration_done?

      r = Economy::SetUpEconomy.new(
          client_token_id: @client_token_id,
          conversion_factor: @ost_to_bt,
          airdrop_bt_per_user: @airdrop_amount,
          initial_number_of_users: @number_of_users
      ).perform

      return r unless r.success?

      @client_token = r.data[:client_token]
      @client_token_planner = r.data[:client_token_planner]

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

      return success if @client_token.propose_initiated? || @client_token.registration_done?

      @parent_tx_activity_type = GlobalConstant::CriticalChainInteractions.propose_bt_activity_type

      @propose_critical_log_obj = CriticalChainInteractionLog.create!(
        {
          client_id: @client_id,
          client_token_id: @client_token_id,
          activity_type: GlobalConstant::CriticalChainInteractions.propose_bt_activity_type,
          chain_type: GlobalConstant::CriticalChainInteractions.utility_chain_type,
          request_params: {
            token_symbol: @client_token.symbol,
            token_name: @client_token.name,
            token_conversion_factor: BigDecimal.new(@client_token.conversion_factor),
            bt_to_mint: @bt_to_mint,
            st_prime_to_mint: @st_prime_to_mint,
            airdrop_amount: @airdrop_amount,
            airdrop_user_list_type: @airdrop_user_list_type
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

      success

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

      @parent_tx_activity_type ||= GlobalConstant::CriticalChainInteractions.staker_initial_transfer_activity_type

      critical_log_obj = nil

      begin

        critical_log_obj = CriticalChainInteractionLog.create!(
            {
                client_id: @client_id,
                client_token_id: @client_token_id,
                parent_id: @stake_and_mint_init_chain_id,
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
            'e_sam_9',
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

    # Enqueue Initiate Airdrop tokens job if required
    #
    # * Author: Pankaj
    # * Date: 26/02/2018
    # * Reviewed By:
    #
    def enqueue_airdrop_tokens_job
      if @airdrop_amount.present? && @airdrop_user_list_type.present?
        BgJob.enqueue(
            Airdrop::InitiateAirdropTokensJob,
            {
                parent_critical_log_id: @stake_and_mint_init_chain_id,
                client_token_id: @client_token_id,
                client_id: @client_id,
                airdrop_amount: @airdrop_amount,
                airdrop_list_type: @airdrop_user_list_type
            },
            {
                wait: 10.seconds
            }
        )
      end

    end

  end

end
