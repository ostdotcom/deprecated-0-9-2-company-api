class CreateClientTransactions < DbMigrationConnection

  def self.up

    run_migration_for_db(EstablishCompanyClientEconomyDbConnection) do
      create_table :client_transactions do |t|
        t.column :client_id, :integer, null: false
        t.column :name, :string, null: false, limit: 50
        t.column :kind, :tinyint, null: false, limit: 1 # 1: user_to_user, 2: user_to_company, 3: company_to_user
        t.column :value_currency_type, :tinyint, null: false, limit: 1 # 1: usd, 2: bt
        t.column :value_in_usd, :decimal, null: true, precision: 10, scale: 5
        t.column :value_in_bt, :decimal, null: true, precision: 30, scale: 0
        t.column :commission_percent, :decimal, null: false, precision: 6, scale: 3
        t.timestamps
      end

      add_index :client_transactions, [:client_id, :name], name: 'index_1'
    end

  end

  def self.down
    run_migration_for_db(EstablishCompanyClientEconomyDbConnection) do
      drop_table :client_transactions
    end
  end

end
