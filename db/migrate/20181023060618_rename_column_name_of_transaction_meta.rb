class RenameColumnNameOfTransactionMeta < DbMigrationConnection
  def up
    run_migration_for_db(EstablishSaasTransactionDbConnection) do
      rename_column :transaction_meta, :next_retry_timestamp, :next_action_at
    end
  end

  def down
    run_migration_for_db(EstablishSaasTransactionDbConnection) do
      rename_column :transaction_meta, :next_action_at, :next_retry_timestamp
    end
  end
end
