class ClientApiCredential < EstablishCompanyClientEconomyDbConnection

  def self.generate_encrypted_secret_key(salt)
    api_secret = Digest::SHA256.hexdigest SecureRandom.hex(12)

    encryptor_obj = LocalCipher.new(salt)
    r = encryptor_obj.encrypt(api_secret)
    fail() unless r.success?

    r.data[:ciphertext_blob]
  end

  def self.generate_random_app_id
    SecureRandom.hex(10)
  end

end


