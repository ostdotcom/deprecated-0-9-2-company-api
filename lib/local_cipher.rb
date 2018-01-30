class LocalCipher

  include Util::ResultHelper

  def initialize(key)
    @key = key
    @splitter = '--'
  end

  def encrypt(plaintext)
    begin
      iv = generate_random_iv
      client.encrypt
      client.key = @key
      client.iv = iv

      encrypted = ''
      encrypted << client.update(plaintext)
      encrypted << client.final
      encryptedString = Base64.encode64(encrypted).gsub(/\n/, '')
      encryptedString += (@splitter + iv)

      success_with_data(
          ciphertext_blob: encryptedString
      )
    rescue Exception => e
      error_with_data('lc_1',
                      "LocalCipher could not encrypt text with message => #{e.message}",
                      'Something Went Wrong.',
                      GlobalConstant::ErrorAction.default,
                      {})
    end
  end

  def decrypt(ciphertext_blob)
    begin

      arr = ciphertext_blob.split(@splitter)
      encryptedString = arr[0]
      iv = arr[1]

      client.decrypt
      client.key = @key
      client.iv = iv
      encryptedString = Base64.urlsafe_decode64(encryptedString)
      plaintext = client.update(encryptedString) + client.final

      success_with_data(
          plaintext: plaintext
      )
    rescue Exception => e
      error_with_data('lc_2',
                      "LocalCipher could not decrypt cipher with message => #{e.message}",
                      'Something Went Wrong.',
                      GlobalConstant::ErrorAction.default,
                      {})
    end
  end

  def get_hashed_text(text)
    OpenSSL::HMAC.hexdigest("SHA256", GlobalConstant::SecretEncryptor.generic_sha_key, text)
  end

  private

  def client
    @client ||= OpenSSL::Cipher.new('aes-256-cbc')
  end

  def generate_random_iv
    # This method will give different result everytime.
    # If you change random method or iv length make sure to test in node-saas as well, because node has IV length restrictions.

    SecureRandom.hex(8)
  end

end