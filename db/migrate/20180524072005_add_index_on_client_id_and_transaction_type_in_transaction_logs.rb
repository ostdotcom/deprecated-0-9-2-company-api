class AddIndexOnClientIdAndTransactionTypeInTransactionLogs < DbMigrationConnection

  def up

    run_migration_for_db(EstablishSaasTransactionDbConnection) do
      add_index :transaction_logs, [:client_id, :transaction_type], name: 'client_id_transaction_type', unique: false
    end

  end

  def down

    run_migration_for_db(EstablishSaasTransactionDbConnection) do
      remove_index :transaction_logs, name: 'client_id_transaction_type'
    end

  end

end
