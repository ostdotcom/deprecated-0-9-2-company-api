class EstablishCompanyUsersDbConnection < ApplicationRecord
  self.abstract_class = true

  def self.config_key
    "company_users_#{Rails.env}"
  end

  def self.applicable_sub_environments
    [
      GlobalConstant::Environment.main_sub_environment
    ]
  end

  self.establish_connection(config_key.to_sym)
end
