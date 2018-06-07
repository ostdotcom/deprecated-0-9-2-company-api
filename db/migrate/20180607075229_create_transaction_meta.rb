class CreateTransactionMeta < DbMigrationConnection
  def up
    run_migration_for_db(EstablishSaasTransactionDbConnection) do

      create_table :transaction_meta do |t|
        t.column :transaction_hash, :string, null: false
        t.column :transaction_uuid, :string, null: false
        t.column :client_id, :integer, null: false
        t.column :kind, :tinyint, limit: 1, null: false
        t.timestamps
      end

      add_index :transaction_meta, [:transaction_hash], name: 'uniq_transaction_hash', unique: true
    end
  end

  def down
    run_migration_for_db(EstablishSaasTransactionDbConnection) do

      drop_table :transaction_meta

    end
  end
end
