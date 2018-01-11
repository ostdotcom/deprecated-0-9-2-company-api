class Client < EstablishCompanyClientDbConnection

  enum status: {
    GlobalConstant::Client.active_status => 1,
    GlobalConstant::Client.inactive_status => 2
  }

end
