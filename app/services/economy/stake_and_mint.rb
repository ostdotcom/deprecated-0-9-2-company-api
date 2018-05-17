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
    # @param [Integer] amount (optional) - BT amount which needs to be airdropped to users
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
      @airdrop_amount = @params[:amount]
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

      r = initiate_task_in_saas
      return r unless r.success?

      @critical_chain_interaction_log_id = r.data[:critical_chain_interaction_log_id]

      r = enqueue_verify_reg_status_job
      return r unless r.success?

      #NOTE: Returned this and not fetched from PendingCriticalInteractionIds to avoid extra query
      success_with_data(
        pending_critical_interactions: {
          @parent_tx_activity_type => @critical_chain_interaction_log_id
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
        'invalid_api_params',
        GlobalConstant::ErrorAction.default
      ) if @transaction_hash.blank? || (@bt_to_mint <= 0 && @st_prime_to_mint <= 0)

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

      return validation_error(
          'e_sam_2',
          'invalid_api_params',
          ['invalid_user_id'],
          GlobalConstant::ErrorAction.default
      ) if @user.blank?

      return error_with_data(
          'e_sam_3',
          'user_not_verified',
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

      return validation_error(
          'e_sam_4',
          'invalid_api_params',
          ['invalid_client_id'],
          GlobalConstant::ErrorAction.default
      ) if @client.blank? || @client[:status] != GlobalConstant::Client.active_status

      r = fetch_client_eth_address
      return r unless r.success?

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

      return validation_error(
          'e_sam_5',
          'invalid_api_params',
          ['invalid_client_token_id'],
          GlobalConstant::ErrorAction.default
      ) if @client_token.blank? || @client_token.status != GlobalConstant::ClientToken.active_status

      return validation_error(
          'e_sam_6',
          'invalid_api_params',
          ['invalid_client_token_id'],
          GlobalConstant::ErrorAction.default
      ) if @client_token.name.blank? || @client_token.symbol.blank? || @client_token.reserve_uuid.blank?

      # if propose was started but registeration not done yet we can not proceed
      if @client_token.propose_initiated? && !@client_token.registration_done?
        return validation_error(
            'e_sam_7',
            'invalid_api_params',
            ['invalid_client_token_id'],
            GlobalConstant::ErrorAction.default
        )
      end

      ct_pending_transactions = CacheManagement::PendingCriticalInteractionIds.
          new([@client_token_id]).fetch[@client_token_id]

      if ct_pending_transactions[GlobalConstant::CriticalChainInteractions.propose_bt_activity_type].present? ||
          ct_pending_transactions[GlobalConstant::CriticalChainInteractions.staker_initial_transfer_activity_type].present?

        return error_with_data(
            'e_sam_7',
            'pending_grant_requests',
            GlobalConstant::ErrorAction.default
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

      return success if @client_token.registration_done?

      @airdrop_amount = @airdrop_amount.present? ? BigDecimal.new(@airdrop_amount) : @airdrop_amount
      @ost_to_bt = @ost_to_bt.present? ? BigDecimal.new(@ost_to_bt) : @ost_to_bt
      @number_of_users = @number_of_users.to_i

      return error_with_data(
          'e_sam_8',
          'invalid_api_params',
          GlobalConstant::ErrorAction.default
      ) if @ost_to_bt.blank? || @bt_to_mint < 0 || @number_of_users < 0 ||
          @airdrop_amount.blank? || @airdrop_amount < 0 || @airdrop_user_list_type.blank?

      success

    end

    # Fetch Eth Address of client
    #
    # * Author: Puneet
    # * Date: 29/01/2018
    # * Reviewed By:
    #
    # Sets @client_eth_address
    #
    # @return [Result::Base]
    #
    def fetch_client_eth_address

      client_address_data = CacheManagement::ClientAddress.new([@client_id]).fetch[@client_id]

      return validation_error(
          'e_sam_10',
          'invalid_api_params',
          ['invalid_client_id'],
          GlobalConstant::ErrorAction.default
      ) if client_address_data.blank? || client_address_data[:ethereum_address_d].blank?

      @client_eth_address = get_encrypted_eth_address(client_address_data[:ethereum_address_d])

      success

    end

    def get_encrypted_eth_address(address)
      digest = OpenSSL::Digest.new('sha256')
      OpenSSL::HMAC.hexdigest(digest, GlobalConstant::SecretEncryptor.generic_sha_key, address.downcase)
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

      return success if @client_token.registration_done?

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

    # Initiate TASK in saas
    #
    # * Author: Puneet
    # * Date: 20/03/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def initiate_task_in_saas
      @client_token.registration_done? ? initiate_stake_and_mint_in_saas : initiate_registeration_in_saas
    end

    # Initiate Registeration TASK in saas (this would setup token + first time stake / mint + airdrop)
    #
    # * Author: Puneet
    # * Date: 20/03/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def initiate_registeration_in_saas

      @parent_tx_activity_type = GlobalConstant::CriticalChainInteractions.propose_bt_activity_type

      params = {
        token_symbol: @client_token.symbol,
        client_id: @client_token.client_id,
        client_token_id: @client_token.id,
        stake_and_mint_params: {
          bt_to_mint: @bt_to_mint,
          st_prime_to_mint: @st_prime_to_mint,
          client_eth_address: @client_eth_address,
          transaction_hash: @transaction_hash
        },
        airdrop_params: {
          airdrop_amount: @airdrop_amount,
          airdrop_user_list_type: @airdrop_user_list_type
        }
      }

      SaasApi::OnBoarding::Start.new.perform(params)

    end

    # Initiate TASK in saas
    #
    # * Author: Puneet
    # * Date: 20/03/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def initiate_stake_and_mint_in_saas

      @parent_tx_activity_type = GlobalConstant::CriticalChainInteractions.staker_initial_transfer_activity_type

      params = {
        token_symbol: @client_token.symbol,
        client_id: @client_token.client_id,
        client_token_id: @client_token.id,
        stake_and_mint_params: {
          bt_to_mint: @bt_to_mint,
          st_prime_to_mint: @st_prime_to_mint,
          client_eth_address: @client_eth_address,
          transaction_hash: @transaction_hash
        }
      }

      SaasApi::StakeAndMint::Start.new.perform(params)

    end

    # Enqueue job which would observe DB to check if registeration is complete.
    #
    # * Author: Puneet
    # * Date: 29/03/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def enqueue_verify_reg_status_job

      BgJob.enqueue(
        ::RegisterBrandedToken::GetProposeStatusJob,
        {critical_log_id: @critical_chain_interaction_log_id},
        {wait: 30.seconds}
      )

      success

    end

  end

end
