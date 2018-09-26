class RenameIndexOfCriticalChainInteractionLogs < DbMigrationConnection
  def up
    run_migration_for_db(EstablishCompanySaasSharedDbConnection) do

      remove_index :critical_chain_interaction_logs, name: 'uk_chain_id'

      add_index :critical_chain_interaction_logs, [:transaction_hash, :chain_id, ], name: 'uk_transaction_hash_chain_id', unique: true

    end
  end

  def down
    run_migration_for_db(EstablishCompanySaasSharedDbConnection) do

      remove_index :critical_chain_interaction_logs, name: 'uk_transaction_hash_chain_id'

      add_index :critical_chain_interaction_logs, [:chain_id, :transaction_hash], name: 'uk_chain_id', unique: true

    end
  end
end
