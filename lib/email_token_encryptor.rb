class EmailTokenEncryptor

  def initialize(key)
    @key = key
  end

  def encrypt(string)
    client.encrypt_and_sign(string)
  end

  def decrypt(encrypted_text)
    client.decrypt_and_verify(encrypted_text)
  end

  private

  def client
    ActiveSupport::EmailTokenEncryptor.new(GlobalConstant::SecretEncryptor.email_tokens_key)
  end
end