class CreateExchangeTradeData < DbMigrationConnection
  def up
    run_migration_for_db(EstablishSaasAnalyticsDbConnection) do
      create_table :exchange_trade_data do |t|
        t.column :exchange, :tinyint, null: false
        t.column :trading_pair, :tinyint, null: false
        t.column :timestamp, :integer, null: false
        t.column :price, :decimal, precision: 24, scale: 12, null: false
        t.column :quantity, :decimal, precision: 16, scale: 6, null: false
        t.column :extra_data, :string, null: true
        t.timestamps
      end
    end
  end
  
  def down
    run_migration_for_db(EstablishSaasAnalyticsDbConnection) do
      drop_table :exchange_trade_data
    end
  end
end