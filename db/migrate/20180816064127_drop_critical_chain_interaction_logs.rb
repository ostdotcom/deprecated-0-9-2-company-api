class DropCriticalChainInteractionLogs < DbMigrationConnection
  
  def change
    run_migration_for_db(EstablishCompanyBigDbConnection) do
      drop_table :critical_chain_interaction_logs
    end
  end
end
