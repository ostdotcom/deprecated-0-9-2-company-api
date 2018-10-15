class TxMetaRestructureErrorHandling < DbMigrationConnection
  def up
    completed_status = 0
    default_retry_count = 0
    run_migration_for_db(EstablishSaasTransactionDbConnection) do
      add_column :transaction_meta, :status, :integer, after: :client_id, :null => false, default:completed_status
      add_column :transaction_meta, :retry_count, :tinyint, after: :kind, :null => false, default: default_retry_count
      add_index :transaction_meta, [:transaction_uuid], name: 'uk_tx_uuid', unique: true
      change_column_null :transaction_meta, :transaction_hash, null: true
    end
  end

  def down
    run_migration_for_db(EstablishSaasTransactionDbConnection) do
      change_column_null :transaction_meta, :transaction_hash, null: false
      remove_index :transaction_meta, name: 'uk_tx_uuid'
      remove_column :transaction_meta, :retry_count
      remove_column :transaction_meta, :status
    end
  end
end
