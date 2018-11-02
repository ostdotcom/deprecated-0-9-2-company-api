class EstablishSaasAnalyticsDbConnection < ApplicationRecord
  
  self.abstract_class = true
  
  def self.config_key
    "saas_analytics_#{Rails.env}"
  end
  
  def self.applicable_sub_environments
    [
      GlobalConstant::Environment.sandbox_sub_env
    ]
  end
  
  self.establish_connection(config_key.to_sym)
  
end
