class CreateTransactionLogs < DbMigrationConnection
  def change
    run_migration_for_db(EstablishSaasTransactionDbConnection) do

      create_table :transaction_logs do |t|
        t.column :uuid, :string, null: false
        t.column :transaction_hash, :string, null: true
        t.column :chain, :tinyint, limit: 1, null: false
        t.column :params, :text, null: true
        t.column :status, :tinyint, limit: 1, null: false
        t.timestamps
      end

      add_index :transaction_logs, [:uuid], name: 'uniq_uuid', uniq: true
      add_index :transaction_logs, [:transaction_hash], name: 'uniq_transaction_hash', uniq: true

    end
  end

  def down
    run_migration_for_db(EstablishSaasTransactionDbConnection) do

      drop_table :transaction_logs

    end
  end
end
