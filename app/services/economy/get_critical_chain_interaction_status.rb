module Economy

  class GetCriticalChainInteractionStatus < ServicesBase

    # Initialize
    #
    # * Author: Puneet
    # * Date: 31/01/2018
    # * Reviewed By:
    #
    # @params [Integer] critical_chain_interaction_log_id (mandatory) - critical_chain_interaction_log_id
    # @params [Integer] client_token_id (mandatory) - client token id
    #
    # @return [Economy::GetCriticalChainInteractionStatus]
    #
    def initialize(params)

      super

      @critical_chain_interaction_log_id = @params[:critical_chain_interaction_log_id]

      @api_response_data = {result_type: result_type}

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

      r = fetch_critical_chain_interaction_status
      return r unless r.success?

      #TODO: We could add validations here to check if parent id of all these txs was owned by client_token_id
      success_with_data(@api_response_data)

    end

    private

    #
    # * Author: Puneet
    # * Date: 31/01/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def validate_and_sanitize

      r = validate
      return r unless r.success?

      return validation_error(
          'cm_vea_2',
          'invalid_api_params',
          ['invalid_critical_chain_interaction_log_id'],
          GlobalConstant::ErrorAction.default
      ) unless Util::CommonValidator.is_numeric?(@critical_chain_interaction_log_id)

      @critical_chain_interaction_log_id = @critical_chain_interaction_log_id.to_i

      success

    end

    #
    # * Author: Puneet
    # * Date: 31/01/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def fetch_critical_chain_interaction_status

      @api_response_data[result_type] = CacheManagement::CriticalChainInteractionStatus.
          new([@critical_chain_interaction_log_id]).fetch[@critical_chain_interaction_log_id]

      success

    end

    def result_type
      :critical_chain_interaction_status
    end

  end

end

