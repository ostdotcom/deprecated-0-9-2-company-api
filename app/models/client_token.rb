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

end
