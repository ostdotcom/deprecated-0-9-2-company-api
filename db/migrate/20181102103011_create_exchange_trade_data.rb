class CreateExchangeTradeData < DbMigrationConnection
  def up
    run_migration_for_db(EstablishSaasAnalyticsDbConnection) do
      create_table :exchange_trade_data do |t|
        t.column :exchange, :string, null: false
        t.column :trading_pair, :string, null: false
        t.column :trade_id, :integer, null: false
        t.column :timestamp, :integer, limit: 8, null: false
        t.column :price, :decimal, precision: 24, scale: 12, null: false
        t.column :quantity, :decimal, precision: 16, scale: 6, null: false
        t.column :extra_data, :string, null: true
        t.timestamps
      end
      add_index :exchange_trade_data, [:exchange, :trading_pair, :trade_id], unique: true, name: 'uk_trade_exchange_pair_id_uniq'
    end
  end
  
  def down
    run_migration_for_db(EstablishSaasAnalyticsDbConnection) do
      remove_index :exchange_trade_data, name: 'uk_trade_exchange_pair_id_uniq'
      drop_table :exchange_trade_data
    end
  end
end