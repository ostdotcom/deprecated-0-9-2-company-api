class CreateExchangePricesData < DbMigrationConnection
  def up
    run_migration_for_db(EstablishSaasAnalyticsDbConnection) do
      create_table :exchange_price_data do |t|
        t.column :exchange, :tinyint, size: 1, null: false
        t.column :trading_pair, :tinyint, size: 1, null: false
        t.column :timestamp, :integer, limit: 8, null: false
        t.column :price, :decimal, precision: 24, scale: 12, null: false
        t.timestamps
      end
      add_index :exchange_price_data, [:trading_pair, :exchange], unique: false, name: 'uk_trade_exchange_pair_date_uniq'
    end
  end
  
  def down
    run_migration_for_db(EstablishSaasAnalyticsDbConnection) do
      drop_table :exchange_price_data
    end
  end
end