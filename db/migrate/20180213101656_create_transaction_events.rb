class CreateTransactionEvents < DbMigrationConnection
  def up
    run_migration_for_db(EstablishSaasTransactionDbConnection) do

      create_table :transaction_events do |t|
        t.column :uuid, :string, null: false
        t.column :transaction_hash, :string, null: true
        t.column :chain, :tinyint, limit: 1, null: false
        t.column :tag, :string, null: true
        t.column :event_data, :text, null: true
        t.column :status, :tinyint, limit: 1, null: false
        t.timestamps
      end

      add_index :transaction_events, [:uuid], name: 'index_uuid'
      add_index :transaction_events, [:transaction_hash], name: 'index_transaction_hash'

    end
  end

  def down
    run_migration_for_db(EstablishSaasTransactionDbConnection) do

      drop_table :transaction_events

    end
  end
end
