module CheckTransactionStatusJob

  class GetTestOst < CheckTransactionStatusJob::Base

    # Check if Tx to grant Test Ost was mined
    #
    # * Author: Puneet
    # * Date: 12/02/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def perform(params)
      super
    end

    private

    # Initialize params
    #
    # * Author: Puneet
    # * Date: 12/02/2018
    # * Reviewed By:
    #
    # @param [Integer] critical_chain_interaction_id (mandatory) - Client Chain Interaction Id
    # @param [Integer] first_enqueue_timestmap (mandatory) - timestamp when this job was first enqueued
    # @param [String] transaction_uuid (optional) - uuid on basis of which we could look up tx status from SAAS
    # @param [String] transaction_hash (optional) - hash on basis of which we could look up tx status from SAAS
    #
    def initialize_params(params)

      super

      @critical_chain_interaction_id = @params[:critical_chain_interaction_id]

    end

    # Validate Params
    #
    # * Author: Puneet
    # * Date: 12/02/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def validate_params

      r = super
      return r unless r.success?

      return error_with_data(
          'j_cts_gto_1',
          'Blank client_chain_interaction_id.',
          'Blank client_chain_interaction_id.',
          GlobalConstant::ErrorAction.default,
          {}
      ) if @client_chain_interaction_id.blank?

      return error_with_data(
          'j_cts_gto_2',
          'Invalid client_chain_interaction_id.',
          'Invalid client_chain_interaction_id.',
          GlobalConstant::ErrorAction.default,
          {}
      ) if client_chain_interaction.blank?

      success

    end

    # DB Object
    #
    # * Author: Puneet
    # * Date: 12/02/2018
    # * Reviewed By:
    #
    # @return [CriticalChainInteractionLog]
    #
    def chain_interaction_log
      @c_c_i ||= CriticalChainInteractionLog.where(id: @critical_chain_interaction_id).first
    end

    # Handle case where tx was succesfully mined
    #
    # * Author: Puneet
    # * Date: 12/02/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def handle_tx_success
      chain_interaction_log.status = GlobalConstant::CriticalChainInteractions.processed_status
      chain_interaction_log.debug_data = {} # fill in data here cherrypicking keys from @tx_details
      chain_interaction_log.save
    end

    # Handle case where tx failed
    #
    # * Author: Puneet
    # * Date: 12/02/2018
    # * Reviewed By:
    #
    # @param [Result::Base] r : error response object
    #
    # @return [Result::Base]
    #
    def handle_tx_failure(r)
      #TODO: Log or mail error ?
      chain_interaction_log.status = GlobalConstant::CriticalChainInteractions.failed_status
      chain_interaction_log.save
    end

    # Max allowed time till which we would wait or else mark tx as failed
    #
    # * Author: Puneet
    # * Date: 12/02/2018
    # * Reviewed By:
    #
    # @return [Time]
    #
    def max_allowed_wait_time
      10.minutes
    end

    # Time after which this job should be retried to check if tx was mined then ?
    #
    # * Author: Puneet
    # * Date: 12/02/2018
    # * Reviewed By:
    #
    # @return [Time]
    #
    def re_enqueue_after
      30.seconds
    end

  end

end
