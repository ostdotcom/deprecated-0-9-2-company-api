class CreateSassClientTokens < DbMigrationConnection
  def up
    run_migration_for_db(EstablishSaasClientEconomyDbConnection) do

      create_table :client_tokens do |t|
        t.column :client_id, :integer, null: false
        t.column :symbol, :string
        t.column :reserve_managed_address_id, :string
        t.column :token_erc20_address, :string
        t.column :token_uuid, :string
        t.column :conversion_rate, :decimal, null: true, precision: 12, scale: 6
        t.timestamps
      end

      add_index :client_tokens, :client_id, name: 'index_client_id'
      add_index :client_tokens, :symbol, name: 'uniq_symbol'
    end
  end

  def down
    run_migration_for_db(EstablishSaasClientEconomyDbConnection) do

      drop_table :client_tokens

    end
  end
end
