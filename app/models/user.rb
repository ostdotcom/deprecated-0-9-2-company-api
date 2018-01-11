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

end
