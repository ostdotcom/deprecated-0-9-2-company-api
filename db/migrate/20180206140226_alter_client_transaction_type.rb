class AlterClientTransactionType < DbMigrationConnection

  def up
    run_migration_for_db(EstablishCompanyClientEconomyDbConnection) do
      add_column :client_transaction_types, :use_price_oracle, :tinyint, null: false, after: :commission_percent
    end
  end

  def down
    run_migration_for_db(EstablishCompanyClientEconomyDbConnection) do
      remove_column :client_transaction_types, :use_price_oracle
    end
  end

end
