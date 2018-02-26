class ClientToken < EstablishCompanyClientEconomyDbConnection

  enum status: {
    GlobalConstant::ClientToken.active_status => 1,
    GlobalConstant::ClientToken.inactive_status => 2
  }

  def self.setup_steps_config
    @u_props ||= {
      GlobalConstant::ClientToken.token_worth_in_usd_setup_step => 1,
      GlobalConstant::ClientToken.configure_transactions_setup_step => 2,
      GlobalConstant::ClientToken.propose_initiated_setup_step => 4,
      GlobalConstant::ClientToken.propose_done_setup_step => 8,
      GlobalConstant::ClientToken.registered_on_uc_setup_step => 16,
      GlobalConstant::ClientToken.registered_on_vc_setup_step => 32,
      GlobalConstant::ClientToken.received_test_ost_setup_step => 64,
      GlobalConstant::ClientToken.airdrop_done_setup_step => 128
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
        name: name,
        symbol: symbol,
        symbol_icon: symbol_icon,
        status: status,
        conversion_factor: conversion_factor.present? ? conversion_factor.to_s : conversion_factor, # should be string as it goes to FE
        setup_steps: setup_steps.present? ? ClientToken.get_bits_set_for_setup_steps(setup_steps) : []
    }
  end

  # Format data to a format which goes into secure cache
  #
  # * Author: Puneet
  # * Date: 01/02/2018
  # * Reviewed By:
  #
  # @return [Hash]
  #
  def formated_secure_cache_data
    {
        id: id,
        token_erc20_address: token_erc20_address,
        reserve_uuid: reserve_uuid
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

end
