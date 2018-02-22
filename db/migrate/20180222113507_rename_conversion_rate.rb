class RenameConversionRate < DbMigrationConnection

  def up

    run_migration_for_db(EstablishCompanyClientEconomyDbConnection) do
      rename_column :client_tokens, :conversion_rate, :conversion_factor
    end

    run_migration_for_db(EstablishSaasClientEconomyDbConnection) do
      rename_column :client_branded_tokens, :conversion_rate, :conversion_factor
    end

  end


  def down

    run_migration_for_db(EstablishCompanyClientEconomyDbConnection) do
      rename_column :client_tokens, :conversion_factor, :conversion_rate
    end

    run_migration_for_db(EstablishSaasClientEconomyDbConnection) do
      rename_column :client_branded_tokens, :conversion_factor, :conversion_rate
    end

  end

end
