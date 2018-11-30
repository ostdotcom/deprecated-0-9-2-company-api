class ChangeColumnTradeIdOfExchangeTradeData < DbMigrationConnection
  def up
    run_migration_for_db(EstablishSaasAnalyticsDbConnection) do
      change_column_null :exchange_trade_data, :trade_id, true
    end
  
  end
  
  def down
    
    run_migration_for_db(EstablishSaasAnalyticsDbConnection) do
      change_column_null :exchange_trade_data, :trade_id, false
    end
  
  end
end