class AddStatusConfigStrategiesAndChainGethProviders < DbMigrationConnection
  def up
    default_inactive_value = 2
    run_migration_for_db(EstablishSaasConfigDbConnection) do
      add_column :config_strategies, :status, :integer, after: :hashed_params, :null => false,default:default_inactive_value
      add_column :chain_geth_providers, :status, :integer, after: :rpc_provider , :null => false, default:default_inactive_value
      add_index :config_strategies, [:group_id, :kind], unique: true, name: 'uk_group_id_kind_uniq'
    end
  end
  def down
    run_migration_for_db(EstablishSaasConfigDbConnection) do
      remove_index :config_strategies, name: 'uk_group_id_kind_uniq'
      remove_column :config_strategies, :status
      remove_column :chain_geth_providers, :status
    end
  end
end