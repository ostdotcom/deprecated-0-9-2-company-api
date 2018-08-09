class CreateChainGethProvidersTable < DbMigrationConnection

  def up

    run_migration_for_db(EstablishSaasConfigDbConnection) do

      create_table :chain_geth_providers do |t|
        t.column :chain_id, :int, limit: 8, null: false
        t.column :chain_kind, :tinyint, null: false
        t.column :ws_provider, :string, limit: 255, null: false
        t.column :rpc_provider, :string, limit: 255, null: false
        t.timestamps
      end

      add_index :chain_geth_providers, [:ws_provider], name: 'chain_geth_ws_providers', unique: true
      add_index :chain_geth_providers, [:rpc_provider], name: 'chain_geth_rpc_providers', unique: true

    end

  end

  def down

    run_migration_for_db(EstablishSaasConfigDbConnection) do

      drop_table :chain_geth_providers

    end

  end

end
