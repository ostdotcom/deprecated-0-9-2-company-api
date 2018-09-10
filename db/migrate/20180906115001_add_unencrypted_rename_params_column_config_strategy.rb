class AddUnencryptedRenameParamsColumnConfigStrategy < DbMigrationConnection
  def up
    run_migration_for_db(EstablishSaasConfigDbConnection) do
      rename_column :config_strategies, :params, :encrypted_params
      add_column :config_strategies, :unencrypted_params, :text, after: :encrypted_params
      change_column_null :config_strategies, :encrypted_params, true
    end
  end
  def down
    run_migration_for_db(EstablishSaasConfigDbConnection) do
      change_column_null :config_strategies, :encrypted_params, false
      rename_column :config_strategies, :encrypted_params, :params
      remove_column :config_strategies, :unencrypted_params
    end
  end
end