class UpdateClientBrandedTokens < DbMigrationConnection

  def up
    run_migration_for_db(EstablishSaasClientEconomyDbConnection) do
      add_column :client_branded_tokens, :name, :string, null: true, after: :reserve_managed_address_id
    end
  end

  def down
    run_migration_for_db(EstablishSaasClientEconomyDbConnection) do
      remove_column :client_branded_tokens, :name
    end
  end

end
