class AddColumnGroupIdToConfigStrategies < DbMigrationConnection
  def up
    run_migration_for_db(EstablishSaasConfigDbConnection) do
      add_column :config_strategies, :group_id, :string, limit: 255, after: :id, :null => true
    end
  end

  def down
    run_migration_for_db(EstablishSaasConfigDbConnection) do
      remove_column :config_strategies, :group_id
    end
  end
end
