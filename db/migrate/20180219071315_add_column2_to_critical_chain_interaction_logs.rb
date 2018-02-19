class AddColumn2ToCriticalChainInteractionLogs < DbMigrationConnection
  def up

    run_migration_for_db(EstablishCompanyBigDbConnection) do

      add_column :critical_chain_interaction_logs, :request_params, :text, null: true

      rename_column :critical_chain_interaction_logs, :debug_data, :response_data

    end

  end

  def down

    run_migration_for_db(EstablishCompanyBigDbConnection) do

      remove_column :request_params, :request_params

      rename_column :critical_chain_interaction_logs, :response_data, :debug_data

    end

  end

end
