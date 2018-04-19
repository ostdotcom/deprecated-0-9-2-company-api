class AddIndexInTransactionLogs < DbMigrationConnection

  def up

    run_migration_for_db(EstablishSaasTransactionDbConnection) do
      add_index :transaction_logs, [:transaction_hash], name: 'uniq_transaction_hash', unique: true
    end

  end

  def down

    run_migration_for_db(EstablishSaasTransactionDbConnection) do
      remove_index :transaction_logs, name: 'uniq_transaction_hash'
    end

  end

end
