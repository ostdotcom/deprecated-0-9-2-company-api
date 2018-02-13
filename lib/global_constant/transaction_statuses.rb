# frozen_string_literal: true
module GlobalConstant

  class TransactionStatuses

    class << self

      def pending_status
        'pending'
      end

      def processed_status
        'processed'
      end

      def failed_status
        'failed'
      end

    end

  end

end