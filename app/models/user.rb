class User < EstablishCompanyUserDbConnection

  enum status: {
    GlobalConstant::User.active_status => 1,
    GlobalConstant::User.inactive_status => 2,
    GlobalConstant::User.blocked_status => 3
  }

  def self.properties_config
    @u_props ||= {
      GlobalConstant::User.is_client_manager_property => 1
    }
  end

  def self.bit_wise_columns_config
    @b_w_c_c ||= {
      properties: properties_config
    }
  end

  # Note : always include this after declaring bit_wise_columns_config method
  include BitWiseConcern


  def self.get_memcache_key_object
    MemcacheKey.new('user.user_details')
  end

  def self.get_from_memcache(user_id)
    memcache_key_object = User.get_memcache_key_object
    Memcache.get_set_memcached(memcache_key_object.key_template % {id: user_id}, memcache_key_object.expiry) do
      User.where(id: user_id).first
    end
  end

  # Get encrypted password
  #
  # * Author: Pankaj
  # * Date: 11/08/2017
  # * Reviewed By:
  #
  # @param [String] password
  # @param [String] salt
  #
  # @return [String] MD5 Encrypted password
  #
  def self.get_encrypted_password(password, salt)
    begin
      Digest::MD5.hexdigest("#{password}::#{salt}")
    rescue Encoding::CompatibilityError => e
      p = password.to_s.force_encoding("UTF-8")
      s = salt.to_s.force_encoding("UTF-8")
      Digest::MD5.hexdigest("#{p}::#{s}")
    end
  end

end
