class AddColumnToCriticalChainInteractionLogs < DbMigrationConnection
  def up

    run_migration_for_db(EstablishCompanyBigDbConnection) do

      add_column :critical_chain_interaction_logs, :parent_id, :integer, after: :id

      add_index :critical_chain_interaction_logs, [:client_id, :activity_type, :client_token_id], name: 'index_1'

    end

  end

  def down

    run_migration_for_db(EstablishCompanyBigDbConnection) do

      remove_column :critical_chain_interaction_logs, :parent_id

      remove_index :critical_chain_interaction_logs, name: 'index_1'

    end

  end

end
