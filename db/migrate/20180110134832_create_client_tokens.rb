class CreateClientTokens < DbMigrationConnection

  def up

    run_migration_for_db(EstablishCompanyClientEconomyDbConnection) do

      create_table :client_tokens do |t|
        t.column :client_id, :integer, null: false
        t.column :name, :string, null: false
        t.column :symbol, :string, null: false
        t.column :symbol_icon, :string, null: true
        t.column :conversion_rate, :decimal, precision: 15, scale: 5, null: true
        t.column :reserve_uuid, :string, null: true
        t.column :token_erc20_address, :string, null: true
        t.column :setup_steps, :tinyint, null: true
        t.column :status, :tinyint, null: false
        t.timestamps
      end

      add_index :client_tokens, [:client_id, :status], name: 'index_1'
      add_index :client_tokens, :name, name: 'uk_1', unique: true
      add_index :client_tokens, :symbol, name: 'uk_2', unique: true

      execute ("ALTER TABLE client_tokens AUTO_INCREMENT = 5000")

    end

  end

  def down
    run_migration_for_db(EstablishCompanyClientEconomyDbConnection) do
      drop_table :client_tokens
    end
  end

end
