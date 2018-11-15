class RemoveDefaultOnStatus < DbMigrationConnection
  def change
    run_migration_for_db(EstablishSaasTransactionDbConnection) do
      change_column_default(:transaction_meta, :status, from: 0, to: nil)
    end
  end
end
