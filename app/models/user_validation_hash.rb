class UserValidationHash < EstablishCompanyUserDbConnection

  enum kind: {
    GlobalConstant::UserValidationHash.reset_password => 1,
    GlobalConstant::UserValidationHash.double_optin => 2
  }

  enum status: {
    GlobalConstant::UserValidationHash.active_status => 1,
    GlobalConstant::UserValidationHash.blocked_status => 2,
    GlobalConstant::UserValidationHash.inactive_status => 3,
    GlobalConstant::UserValidationHash.used_status => 4
  }

  def is_expired?
    expiry_interval = (self.kind == GlobalConstant::UserValidationHash.double_optin) ?
                          GlobalConstant::UserValidationHash.double_opt_in_expiry_interval :
                          GlobalConstant::UserValidationHash.reset_token_expiry_interval
    return (self.created_at.to_i + expiry_interval.to_i) < Time.now.to_i
  end

end
