module Util

  class Converter

    class << self

      # convert from wei
      #
      # * Author: Puneet
      # * Date: 02/02/2018
      # * Reviewed By:
      #
      # @param [BigDecimal] value : value which is in wei and needs to be converted
      #
      # @return [BigDecimal]
      #
      def from_wei_value(value)
        BigDecimal.new(value) / wei_conversion_factor
      end

      # convert to wei
      #
      # * Author: Puneet
      # * Date: 02/02/2018
      # * Reviewed By:
      #
      # @param [BigDecimal] value : value which is in wei and needs to be converted
      #
      # @return [BigDecimal]
      #
      def to_wei_value(value)
        BigDecimal.new(value) * wei_conversion_factor
      end

      # conversion factor for wei conversion
      #
      # * Author: Puneet
      # * Date: 02/02/2018
      # * Reviewed By:
      #
      # @return [BigDecimal]
      #
      def wei_conversion_factor
        BigDecimal.new(10 ** 18)
      end

    end

  end

end