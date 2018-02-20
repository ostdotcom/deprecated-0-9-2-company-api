class CreateClientTokenTransactions < DbMigrationConnection
  def up

    run_migration_for_db(EstablishCompanyClientEconomyDbConnection) do

      create_table :client_token_transactions do |t|
        t.column :client_token_id, :integer, null: false
        t.column :transaction_uuid, :string, limit: 255, null: false
        t.timestamps
      end

      add_index :client_token_transactions, [:client_token_id, :transaction_uuid], unique: true, name: 'index_1'

    end

  end

  def down
    run_migration_for_db(EstablishCompanyClientEconomyDbConnection) do
      drop_table :client_token_transactions
    end
  end

end

