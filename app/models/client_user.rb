class ClientUser < EstablishCompanyClientEconomyDbConnection
  enum status: {
      GlobalConstant::User.active_status => 1,
      GlobalConstant::User.inactive_status => 2,
      GlobalConstant::User.auto_blocked_status => 3
  }

end
