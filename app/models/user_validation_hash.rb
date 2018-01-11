class UserValidationHash < EstablishCompanyUserDbConnection

  enum kind: {
    GlobalConstant::UserValidationHash.reset_password => 1,
    GlobalConstant::UserValidationHash.double_optin => 2
  }

  enum status: {
    GlobalConstant::UserValidationHash.active_status => 1,
    GlobalConstant::UserValidationHash.blocked_status => 2,
    GlobalConstant::UserValidationHash.inactive_status => 3
  }

end
