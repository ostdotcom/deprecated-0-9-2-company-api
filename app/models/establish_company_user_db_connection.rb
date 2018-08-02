class EstablishCompanyUserDbConnection < ApplicationRecord

  self.abstract_class = true

  def self.config_key
    "company_user_#{Rails.env}"
  end

  def self.applicable_sub_environments
    [
      GlobalConstant::Environment.main_sub_environment,
      GlobalConstant::Environment.sandbox_sub_env # TEMp change - remove this when deployment of both sandbox and main is done everytime.
    ]
  end

  self.establish_connection(config_key.to_sym)

end
