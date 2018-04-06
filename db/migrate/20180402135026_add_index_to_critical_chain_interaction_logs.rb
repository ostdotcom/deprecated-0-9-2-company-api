class AddIndexToCriticalChainInteractionLogs < DbMigrationConnection
  def up
    run_migration_for_db(EstablishCompanySaasSharedDbConnection) do
      add_index :critical_chain_interaction_logs, [:transaction_hash], name: 'tx_hash', unique: true
    end
  end

  def down
    run_migration_for_db(EstablishCompanySaasSharedDbConnection) do
      remove_index :critical_chain_interaction_logs, name: 'tx_hash'
    end
  end
end
