class AlterCommissionPercentInClientTransactionTypes < DbMigrationConnection

  def up
    run_migration_for_db(EstablishSaasClientEconomyDbConnection) do
      change_column :client_transaction_types, :commission_percent, :decimal, null: false, precision: 6, scale: 2
    end
  end

  def down
    run_migration_for_db(EstablishSaasClientEconomyDbConnection) do
      change_column :client_transaction_types, :commission_percent, :decimal, null: false, precision: 6, scale: 3
    end
  end

end
