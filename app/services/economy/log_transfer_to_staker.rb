module Economy

  class LogTransferToStaker < ServicesBase

    # Initialize
    #
    # * Author: Puneet
    # * Date: 31/01/2018
    # * Reviewed By:
    #
    # @params [Integer] client_id (mandatory) - client id
    # @params [Integer] user_id (mandatory) - user id
    # @params [Integer] client_token_id (mandatory) - client token id
    # @params [String] transaction_hash (mandatory) - transaction_hash
    #
    # @return [Economy::LogTransferToStaker]
    #
    def initialize(params)

      super

      @client_id = @params[:client_id]
      @client_token_id = @params[:client_token_id]
      @user_id = @params[:user_id]
      @transaction_hash = @params[:transaction_hash]

      @user = nil
      @client_token = nil
      @chain_interaction_log_id = nil

    end

    # Perform
    #
    # * Author: Puneet
    # * Date: 31/01/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def perform

      r = validate_and_sanitize
      return r unless r.success?

      r = log_transfer
      return r unless r.success?

      enque_job

    end

    private

    # Validate and sanitize
    #
    # * Author: Puneet
    # * Date: 31/01/2018
    # * Reviewed By:
    #
    # Sets @user
    #
    # @return [Result::Base]
    #
    def validate_and_sanitize

      r = validate
      return r unless r.success?

      r = validate_user
      return r unless r.success?

      validate_client_token

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
          'e_ltts_1',
          'Invalid User Id',
          'Invalid User Id',
          GlobalConstant::ErrorAction.default,
          {}
      ) if @user.blank? || @user[:properties].exclude?(GlobalConstant::User.is_user_verified_property)

      success

    end

    # Validate Client Token
    #
    # * Author: Puneet
    # * Date: 29/01/2018
    # * Reviewed By:
    #
    # Sets @client_token
    #
    # @return [Result::Base]
    #
    def validate_client_token

      @client_token = ClientToken.where(id: @client_token_id).first

      return error_with_data(
          'e_ltts_1',
          'Invalid User Id',
          'Invalid User Id',
          GlobalConstant::ErrorAction.default,
          {}
      ) if @client_token.blank? || @client_token.client_id != @client_id

      success

    end

    # Log Transfer
    #
    # * Author: Puneet
    # * Date: 29/01/2018
    # * Reviewed By:
    #
    # Sets @chain_interaction_log_id
    #
    # @return [Result::Base]
    #
    def log_transfer

      db_record = CriticalChainInteractionLog.create!(
        client_id: @client_id,
        client_token_id: @client_token_id,
        activity_type: GlobalConstant::CriticalChainInteractions.transfer_to_staker_activty_type,
        chain_type: GlobalConstant::CriticalChainInteractions.value_chain_type,
        status: GlobalConstant::CriticalChainInteractions.pending_status,
        transaction_hash: @transaction_hash
      )

      @chain_interaction_log_id = db_record.id

      success

    end

    # Enqueue a job which would observe this transaction (to check if it was mined)
    #
    # * Author: Puneet
    # * Date: 29/01/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def enqueue_job

      BgJob.enqueue(
          Stake::GetTransferToStakerStatusJob,
          {
              transaction_hash: @transaction_hash,
              critical_chain_interaction_log_id: @chain_interaction_log_id,
              started_at: current_timestamp
          },
          {
              wait: 30.seconds
          }
      )

    end

  end

end
