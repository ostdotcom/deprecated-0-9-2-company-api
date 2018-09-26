class AddColumnAndIndexToCriticalChainInteractionLogs < DbMigrationConnection
  def up

    run_migration_for_db(EstablishCompanySaasSharedDbConnection) do

      add_column :critical_chain_interaction_logs, :chain_id, :integer, after: :id, :null => true

      remove_index :critical_chain_interaction_logs, name: 'uk_1'

      add_index :critical_chain_interaction_logs, [:chain_id, :transaction_hash], name: 'uk_chain_id', unique: true

    end
  end

  def down

    run_migration_for_db(EstablishCompanySaasSharedDbConnection) do

      remove_index :critical_chain_interaction_logs, name: 'uk_chain_id'

      add_index :critical_chain_interaction_logs, [:transaction_hash], name: 'uk_1', unique: true

      remove_column :critical_chain_interaction_logs, :chain_id

    end

  end

end

