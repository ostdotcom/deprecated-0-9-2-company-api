class LocalCipher

  include Util::ResultHelper

  def initialize(key)
    @key = key
  end

  def encrypt(plaintext)
    begin
      ciphertext_blob = client.encrypt_and_sign(plaintext)

      success_with_data(
          ciphertext_blob: ciphertext_blob
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
      plaintext = client.decrypt_and_verify(ciphertext_blob)

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

  private

  def client
    @client ||= ActiveSupport::MessageEncryptor.new(@key, cipher: 'aes-256-cbc')
  end

end