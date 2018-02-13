class CreateTransactionLogsTable < DbMigrationConnection
  def change
    run_migration_for_db(EstablishCompanyTransactionDbConnection) do

      create_table :transaction_logs do |t|
        t.column :uuid, :string, null: false
        t.column :tx_hash, :string, null: true
        t.column :chain, :tinyint, null: false
        t.column :params, :text, null: true
        t.column :status, :tinyint, limit: 1, null: false
        t.timestamps
      end

    end
  end

  def down
    run_migration_for_db(EstablishCompanyTransactionDbConnection) do

      drop_table :transaction_logs

    end
  end
end
