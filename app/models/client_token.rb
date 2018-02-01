class ClientToken < EstablishCompanyClientEconomyDbConnection

  enum status: {
    GlobalConstant::ClientToken.active_status => 1,
    GlobalConstant::ClientToken.inactive_status => 2
  }

  def self.setup_steps_config
    @u_props ||= {
      GlobalConstant::ClientToken.propose_initiated_setup_step => 1,
      GlobalConstant::ClientToken.propose_done_setup_step => 2,
      GlobalConstant::ClientToken.registered_on_uc_setup_step => 4,
      GlobalConstant::ClientToken.registered_on_vc_setup_step => 8
    }
  end

  def self.bit_wise_columns_config
    @b_w_c_c ||= {
      setup_steps: setup_steps_config
    }
  end

  # Note : always include this after declaring bit_wise_columns_config method
  include BitWiseConcern

  # Is registration done
  #
  # * Author: Puneet
  # * Date: 29/01/2018
  # * Reviewed By:
  #
  # @return [Boolean]
  #
  def registration_done?
    send("#{GlobalConstant::ClientToken.propose_done_setup_step}?") &&
      send("#{GlobalConstant::ClientToken.registered_on_uc_setup_step}?") &&
      send("#{GlobalConstant::ClientToken.registered_on_vc_setup_step}?")
  end

  # Get Reserve address of a client
  #
  # * Author: Pankaj
  # * Date: 31/01/2018
  # * Reviewed By:
  #
  # @return [String]
  #
  def get_reserve_address
    client = Client.where(id: client_id).first
    r = Aws::Kms.new('info','user').decrypt(client.info_salt)
    return nil unless r.success?
    info_salt_d = r.data[:plaintext]

    cma = CompanyManagedAddress.where(id: company_managed_addresses_id).first
    return nil if cma.blank?

    r = LocalCipher.new(info_salt_d).decrypt(cma.ethereum_address)
    return (r.success? ? r.data[:plaintext] : nil)
  end

end
