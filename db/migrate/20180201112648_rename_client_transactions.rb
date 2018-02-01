class RenameClientTransactions < DbMigrationConnection

  def change
    run_migration_for_db(EstablishCompanyClientEconomyDbConnection) do
      rename_table :client_transactions, :client_transaction_types
    end
  end

end
