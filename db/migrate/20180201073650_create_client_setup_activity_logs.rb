class CreateClientSetupActivityLogs < DbMigrationConnection

  def up
    run_migration_for_db(EstablishCompanyClientEconomyDbConnection) do
      create_table :client_setup_activity_logs do |t|
        t.column :client_id, :integer, null: false
        t.column :client_token_id, :integer, null: false
        t.column :activity_type, :tinyint, size: 2, null: false
        t.column :chain_type, :tinyint, size: 1, null: false
        t.column :transaction_hash, :string, null: true
        t.column :debug_data, :text, null: true
        t.column :status, :tinyint, size: 1, null: false
        t.timestamps
      end
      add_index :client_setup_activity_logs, :client_token_id, unique: false, name: 'i_1'
    end
  end

  def down
    run_migration_for_db(EstablishCompanyClientEconomyDbConnection) do
      drop_table :client_setup_activity_logs
    end
  end

end
