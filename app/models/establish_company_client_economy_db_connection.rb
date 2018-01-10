class EstablishCompanyClientEconomyDbConnection < ApplicationRecord
  self.abstract_class = true

  def self.config_key
    "company_client_#{Rails.env}"
    "company_client_economy_#{GlobalConstant::Base.sub_env}_#{Rails.env}"
  end

  def self.applicable_sub_environments
    [
      GlobalConstant::Environment.main_sub_environment,
      GlobalConstant::Environment.sandbox_sub_env
    ]
  end

  self.establish_connection(config_key.to_sym)
end
