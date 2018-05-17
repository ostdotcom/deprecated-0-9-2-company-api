class ChangeColumnComissionPercent < DbMigrationConnection
  def up

    run_migration_for_db(EstablishSaasClientEconomyDbConnection) do
      change_column_null :client_transaction_types, :commission_percent, true
    end

  end

  def down

    run_migration_for_db(EstablishSaasClientEconomyDbConnection) do
      change_column_null :client_transaction_types, :commission_percent, false
    end

  end
end
