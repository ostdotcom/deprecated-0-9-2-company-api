class AlterColumnInClientTokens < DbMigrationConnection
  def up

    run_migration_for_db(EstablishCompanyClientEconomyDbConnection) do
      change_column :client_tokens, :setup_steps, :integer
    end

  end
end
