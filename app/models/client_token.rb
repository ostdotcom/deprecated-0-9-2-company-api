class ClientToken < EstablishCompanyClientEconomyDbConnection

  enum status: {
    GlobalConstant::ClientToken.active_status => 1,
    GlobalConstant::ClientToken.inactive_status => 2
  }

  def self.setup_steps_config
    @u_props ||= {
      GlobalConstant::ClientToken.set_conversion_rate_setup_step => 1,
      GlobalConstant::ClientToken.configure_transactions_setup_step => 2,
      GlobalConstant::ClientToken.propose_initiated_setup_step => 4,
      GlobalConstant::ClientToken.propose_done_setup_step => 8,
      GlobalConstant::ClientToken.registered_on_uc_setup_step => 16,
      GlobalConstant::ClientToken.registered_on_vc_setup_step => 32
    }
  end

  def self.bit_wise_columns_config
    @b_w_c_c ||= {
      setup_steps: setup_steps_config
    }
  end

  # Note : always include this after declaring bit_wise_columns_config method
  include BitWiseConcern

  # Format data to a format which goes into cache
  #
  # * Author: Puneet
  # * Date: 01/02/2018
  # * Reviewed By:
  #
  # @return [Hash]
  #
  def formated_cache_data
    {
        id: id,
        client_id: client_id,
        company_managed_addresses_id: company_managed_addresses_id,
        name: name,
        symbol: symbol,
        symbol_icon: symbol_icon,
        status: status,
        conversion_rate: conversion_rate,
        setup_steps: setup_steps.present? ? ClientToken.get_bits_set_for_setup_steps(setup_steps) : []
    }
  end

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
