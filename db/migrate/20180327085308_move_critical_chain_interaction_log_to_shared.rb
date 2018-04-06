class MoveCriticalChainInteractionLogToShared < DbMigrationConnection

  def up
    run_migration_for_db(EstablishCompanySaasSharedDbConnection) do
      create_table :critical_chain_interaction_logs do |t|
        t.column :client_id, :integer, null: false
        t.column :client_token_id, :integer, null: true
        t.column :client_branded_token_id, :integer, null: true
        t.column :parent_id, :integer, null: true
        t.column :activity_type, :tinyint, size: 4, null: false
        t.column :chain_type, :tinyint, size: 1, null: false
        t.column :transaction_uuid, :string, null: true
        t.column :transaction_hash, :string, null: true
        t.column :request_params, :text, null: true
        t.column :response_data, :text, null: true
        t.column :status, :tinyint, size: 1, null: false
        t.timestamps
      end
      add_index :critical_chain_interaction_logs, :transaction_hash, unique: true, name: 'uk_1'
      add_index :critical_chain_interaction_logs, :client_token_id, unique: false, name: 'i_1'
      add_index :critical_chain_interaction_logs, :parent_id, unique: false, name: 'i_2'
      add_index :critical_chain_interaction_logs, [:client_id, :activity_type, :client_token_id], unique: false, name: 'i_3'
      #TODO: Revisit indexes.
    end
  end

  def down
    run_migration_for_db(EstablishCompanySaasSharedDbConnection) do
      drop_table :critical_chain_interaction_logs
    end
  end

end
