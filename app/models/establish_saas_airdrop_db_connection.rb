class EstablishSaasAirdropDbConnection < ApplicationRecord
  self.abstract_class = true

  def self.config_key
    "saas_airdrop_#{GlobalConstant::Base.sub_env}_#{Rails.env}"
  end

  def self.applicable_sub_environments
    [
      GlobalConstant::Environment.main_sub_environment,
      GlobalConstant::Environment.sandbox_sub_env
    ]
  end

  self.establish_connection(config_key.to_sym)
end
