class CreateCriticalChainInteractionLogs < DbMigrationConnection

  def up
    run_migration_for_db(EstablishCompanyBigDbConnection) do
      create_table :critical_chain_interaction_logs do |t|
        t.column :client_id, :integer, null: false
        t.column :activity_type, :tinyint, size: 2, null: false
        t.column :client_token_id, :integer, null: true
        t.column :chain_type, :tinyint, size: 1, null: false
        t.column :transaction_uuid, :string, null: true
        t.column :transaction_hash, :string, null: true
        t.column :debug_data, :text, null: true
        t.column :status, :tinyint, size: 1, null: false
        t.timestamps
      end
      add_index :critical_chain_interaction_logs, :client_token_id, unique: false, name: 'i_1'
    end
  end

  def down
    run_migration_for_db(EstablishCompanyBigDbConnection) do
      drop_table :critical_chain_interaction_logs
    end
  end

end
