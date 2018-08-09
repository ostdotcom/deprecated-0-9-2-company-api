class ChangeIndexInCriticalChainInteractionLogs < DbMigrationConnection
  def up
    run_migration_for_db(EstablishCompanySaasSharedDbConnection) do
      # remove_index :critical_chain_interaction_logs, name: 'i_2'
      add_index :critical_chain_interaction_logs, [:parent_id, :activity_type], unique: true, name: 'parent_activity_type_uniq'
    end
  end

  def down
    run_migration_for_db(EstablishCompanySaasSharedDbConnection) do
      remove_index :critical_chain_interaction_logs, name: 'parent_activity_type_uniq'
    end
  end
end
