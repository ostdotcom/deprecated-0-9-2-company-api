module CheckTransactionStatusJob

  class Base < ApplicationJob

    queue_as GlobalConstant::Sidekiq.queue_name :default_medium_priority_queue

    include Util::ResultHelper

    # base perform to check status of traansaction and perfrom actions on success / failure
    #
    # * Author: Puneet
    # * Date: 12/02/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def perform(params)

      initialize_params(params)

      r = validate_params
      return unless r.success?

      r = fetch_tx_details
      handle_tx_failure(r) unless r.success?

      if is_tx_pending?

        r = re_enqueue_job
        handle_tx_failure(r) unless r.success?

      elsif is_tx_successful?

        handle_tx_success

      elsif is_tx_failed?

        #TODO: Using data in @tx_details fill in appropriate error message and error data
        r = error_with_data(
            'j_cts_b_4',
            '',
            '',
            GlobalConstant::ErrorAction.default,
            {}
        )
        handle_tx_failure(r)

      else
        fail "unhandled status #{tx_status}"
      end

    end

    private

    # Initialize params
    #
    # * Author: Puneet
    # * Date: 12/02/2018
    # * Reviewed By:
    #
    # @param [Integer] first_enqueue_timestmap (mandatory) - timestamp when this job was first enqueued
    # @param [String] transaction_uuid (optional) - uuid on basis of which we could look up tx status from SAAS
    # @param [String] transaction_hash (optional) - hash on basis of which we could look up tx status from SAAS
    #
    def initialize_params(params)

      @params = params

      @transaction_uuid = @params[:transaction_uuid]
      @transaction_hash = @params[:transaction_hash]

      @first_enqueue_timestmap = @params[:first_enqueue_timestmap]

      @tx_details = {}

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

      return error_with_data(
          'j_cts_b_1',
          'Blank Tx Params.',
          'Blank Tx Params.',
          GlobalConstant::ErrorAction.default,
          {}
      ) if @transaction_hash.blank? && @transaction_uuid.blank?

      return error_with_data(
          'j_cts_b_2',
          'Blank first_enqueue_timestmap.',
          'Blank first_enqueue_timestmap.',
          GlobalConstant::ErrorAction.default,
          {}
      ) if @first_enqueue_timestmap.blank?

      @first_enqueue_timestmap = @first_enqueue_timestmap.to_i

      success

    end

    # call SAAS API to fetch Tx Details
    #
    # * Author: Puneet
    # * Date: 12/02/2018
    # * Reviewed By:
    #
    # Sets @tx_details
    #
    # @return [Result::Base]
    #
    def fetch_tx_details

      #TODO: Implement
      @tx_details = {tx_status: GlobalConstant::TransactionStatuses.pending_status}

      success

    end

    # Is Tx still pending to be mined ?
    #
    # * Author: Puneet
    # * Date: 12/02/2018
    # * Reviewed By:
    #
    # @return [Boolean]
    #
    def is_tx_pending?
      @tx_details[:tx_status] == GlobalConstant::TransactionStatuses.pending_status
    end

    # Is Tx still pending to be mined ?
    #
    # * Author: Puneet
    # * Date: 12/02/2018
    # * Reviewed By:
    #
    # @return [Boolean]
    #
    def is_tx_successful?
      @tx_details[:tx_status] == GlobalConstant::TransactionStatuses.processed_status
    end

    # Is Tx still pending to be mined ?
    #
    # * Author: Puneet
    # * Date: 12/02/2018
    # * Reviewed By:
    #
    # @return [Boolean]
    #
    def is_tx_failed?
      @tx_details[:tx_status] == GlobalConstant::TransactionStatuses.failed_status
    end

    # Re enqueue Job if first enque time was within permissable limit
    # return error if it was older
    #
    # * Author: Puneet
    # * Date: 12/02/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def re_enqueue_job

      return error_with_data(
          'j_cts_b_3',
          'Re enqueue failed as tx mining took longer than expected.',
          'Re enqueue failed as tx mining took longer than expected.',
          GlobalConstant::ErrorAction.default,
          {}
      ) unless is_re_enqueue_job_allowed?

      BgJob.enqueue(
          self.class,
          @params,
          {wait: re_enqueue_after}
      )

      success

    end

    # Can this job be re enqueued
    #
    # * Author: Puneet
    # * Date: 12/02/2018
    # * Reviewed By:
    #
    # @return [Boolean]
    #
    def is_re_enqueue_job_allowed?
      (current_timestamp - @first_enqueue_timestmap) < max_allowed_wait_time.to_i
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
      fail 'sub class to implement'
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
      fail 'sub class to implement'
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
      fail 'sub class to implement'
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
      fail 'sub class to implement'
    end

  end

end
