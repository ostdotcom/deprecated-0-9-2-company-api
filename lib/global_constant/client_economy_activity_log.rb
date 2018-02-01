# frozen_string_literal: true
module GlobalConstant

  class ClientEconomyActivityLog

    class << self

      ########## activity_types #############

      def request_ost_activty_type
        'request_ost'
      end

      ########## chain_types #############

      def utility_chain_type
        'utility'
      end

      def value_chain_type
        'value'
      end

      ########## Statuses #############

      def pending_status
        'pending'
      end

      def processed_status
        'processed'
      end

    end

  end

end
