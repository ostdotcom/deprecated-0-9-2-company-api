class CreateClientBrandedTokens < DbMigrationConnection
  def up
    run_migration_for_db(EstablishSaasClientEconomyDbConnection) do

      create_table :client_branded_tokens do |t|
        t.column :client_id, :integer, null: false
        t.column :reserve_managed_address_id, :integer
        t.column :name, :string, null: false
        t.column :symbol, :string, null: false
        t.column :symbol_icon, :string, null: true
        t.column :token_erc20_address, :string
        t.column :token_uuid, :string
        t.column :conversion_rate, :decimal, precision: 15, scale: 5, null: true
        t.timestamps
      end

      add_index :client_branded_tokens, :client_id, name: 'index_client_id'
      add_index :client_branded_tokens, :symbol, name: 'uniq_symbol'

      execute ("ALTER TABLE client_branded_tokens AUTO_INCREMENT = 30000")
    end
  end

  def down
    run_migration_for_db(EstablishSaasClientEconomyDbConnection) do

      drop_table :client_branded_tokens

    end
  end
end
