class AddProcessUuidInTransactionLogs < DbMigrationConnection
  def up
    run_migration_for_db(EstablishSaasTransactionDbConnection) do

      add_column :transaction_logs, :process_uuid, :string, :null => true, :after => :chain_type

    end
  end

  def down
    run_migration_for_db(EstablishSaasTransactionDbConnection) do

      remove_column :transaction_logs, :process_uuid

    end
  end
end

