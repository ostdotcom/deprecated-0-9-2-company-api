class RemoveIndexFromTransactionLogs < DbMigrationConnection
  def up
    if !Rails.env.production?
      run_migration_for_db(EstablishSaasTransactionDbConnection) do
        remove_index :transaction_logs, name: 'index_1'
        remove_index :transaction_logs, name: 'uniq_transaction_hash'
      end
      run_migration_for_db(EstablishSaasClientEconomyDbConnection) do
        remove_index :managed_addresses, name: 'uk_2'
      end
    end
  end

  def down
    if !Rails.env.production?
      run_migration_for_db(EstablishSaasTransactionDbConnection) do
        add_index :transaction_logs, [:transaction_uuid], name: 'index_1', unique: true
        add_index :transaction_logs, [:transaction_hash], name: 'uniq_transaction_hash', unique: true
      end
      run_migration_for_db(EstablishSaasClientEconomyDbConnection) do
        add_index :managed_addresses, [:managed_address_salt_id], name: 'uk_2', unique: true
      end
    end
  end
end
