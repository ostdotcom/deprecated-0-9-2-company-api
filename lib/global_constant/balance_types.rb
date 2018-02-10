# frozen_string_literal: true
module GlobalConstant

  class BalanceTypes

    class << self

      def eth_balance_type
        'eth'
      end

      def ost_balance_type
        'ost'
      end

      def ost_prime_balance_type
        'ostPrime'
      end

      def branded_token_balance_type
        'brandedToken'
      end

      def all_supported_types
        [
            eth_balance_type,
            ost_balance_type,
            ost_prime_balance_type,
            branded_token_balance_type
        ]
      end

    end

  end

end