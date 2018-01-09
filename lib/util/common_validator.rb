module Util
  class CommonValidator

    REGEX_EMAIL = /\A[A-Z0-9]+[A-Z0-9_%+-]*(\.[A-Z0-9_%+-]{1,})*@(?:[A-Z0-9](?:[A-Z0-9-]*[A-Z0-9])?\.)+[A-Z]{2,24}\Z/mi


    # Check for numeric-ness of an input
    #
    # * Author: Kedar
    # * Date: 09/10/2017
    # * Reviewed By: Sunil
    #
    # @return [Boolean] returns a boolean
    #
    def self.is_numeric?(object)
      true if Float(object) rescue false
    end

    # front end sends 0 / 1 instead of boolean true / false
    # Check for booblean-ness of an input
    # check if '0' or '1' was passed
    #
    # * Author: Kedar
    # * Date: 09/10/2017
    # * Reviewed By: Sunil
    #
    # @return [Boolean] returns a boolean
    #
    def self.is_boolean_string?(object)
      %w(0 1).include?(object.to_s)
    end

    # Is boolean
    #
    # * Author: Kedar
    # * Date: 09/10/2017
    # * Reviewed By: Sunil
    #
    # @return [Boolean] returns a boolean
    #
    def self.is_boolean?(object)
      [
          true,
          false
      ].include?(object)
    end

    # Check for numeric-ness of multiple inputs
    #
    # * Author: Kedar
    # * Date: 09/10/2017
    # * Reviewed By: Sunil
    #
    # @return [Boolean] returns a boolean
    #
    def self.are_numeric?(objects)
      return false unless objects.is_a?(Array)
      are_numeric = true
      objects.each do |object|
        unless self.is_numeric?(object)
          are_numeric = false
          break
        end
      end
      return are_numeric
    end

    # Is the given object Hash
    #
    # * Author: Kedar
    # * Date: 09/10/2017
    # * Reviewed By: Sunil
    #
    # @return [Boolean] returns a boolean
    #
    def self.is_a_hash?(obj)
      obj.is_a?(Hash) || obj.is_a?(ActionController::Parameters)
    end

    # Is the Email a Valid Email
    #
    # * Author: Puneet
    # * Date: 10/10/2017
    # * Reviewed By: Sunil
    #
    # @return [Boolean] returns a boolean
    #
    def self.is_valid_email?(email)
      email =~ REGEX_EMAIL
    end

    # Is alpha numeric string
    #
    # * Author: Aman
    # * Date: 20/10/2017
    # * Reviewed By: Sunil
    #
    # @return [Boolean] returns a boolean
    #
    def self.is_alphanumeric?(name)
      name =~ /\A[A-Z0-9]+\Z/i
    end

    # Should Email be send to this email & this env
    #
    # * Author: Puneet
    # * Date: 10/10/2017
    # * Reviewed By: Sunil
    #
    # @return [Boolean] returns a boolean
    #
    def self.is_email_send_allowed?(email)
      return false unless is_valid_email?(email)
      Rails.env.production? || [
          ''
      ].include?(email)
    end

    # check if the addr is a valid address
    #
    # * Author: Kedar
    # * Date: 12/10/2017
    # * Reviewed By: Sunil
    #
    # @return [Boolean] returns a boolean
    #
    def self.is_ethereum_address?(addr)
      !(/^(0x|0X)?[a-fA-F0-9]{40}$/.match(addr.to_s)).nil?
    end

    # Sanitize Ethereum Address
    #
    # * Author: Abhay
    # * Date: 31/10/2017
    # * Reviewed By: Kedar
    #
    # @return [String] returns sanitized ethereum address
    #
    def self.sanitize_ethereum_address(address)
      ethereum_address = address.to_s.strip
      if (!ethereum_address.start_with?('0x') && !ethereum_address.start_with?('0X'))
        ethereum_address = '0x' + ethereum_address
      end
      ethereum_address
    end

  end

end
