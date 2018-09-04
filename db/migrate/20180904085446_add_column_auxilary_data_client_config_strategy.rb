class AddColumnAuxilaryDataClientConfigStrategy < DbMigrationConnection
  def up
    run_migration_for_db(EstablishSaasConfigDbConnection) do
      add_column :client_config_strategies, :auxilary_data, :text, after: :config_strategy_id, :null => true
    end
  end

  def down
    run_migration_for_db(EstablishSaasConfigDbConnection) do
      remove_column :client_config_strategies, :auxilary_data
    end
  end
end
