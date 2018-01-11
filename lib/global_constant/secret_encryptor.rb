# frozen_string_literal: true
module GlobalConstant

  class SecretEncryptor

    class << self

      def cookie_key
        GlobalConstant::Base.secret_encryptor['cookie_secret_key']
      end

      def email_tokens_key
        GlobalConstant::Base.secret_encryptor['email_tokens_decriptor_key']
      end

    end

  end

end
