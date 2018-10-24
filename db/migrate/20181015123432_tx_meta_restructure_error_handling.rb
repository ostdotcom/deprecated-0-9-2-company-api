class TxMetaRestructureErrorHandling < DbMigrationConnection
  def up

    EstablishSaasTransactionDbConnection.connection.execute "
    ALTER TABLE transaction_meta
    ADD COLUMN status INT NOT NULL DEFAULT 0 AFTER client_id,
    ADD COLUMN retry_count TINYINT NOT NULL DEFAULT 0 after kind,
    ADD COLUMN next_action_at INT after retry_count,
    ADD COLUMN lock_id DECIMAL(20,5) after next_action_at,
    ADD UNIQUE uk_tx_uuid (transaction_uuid),
    ADD INDEX idx_lock_id (lock_id),
    MODIFY COLUMN transaction_hash VARCHAR(255)"
    end

  def down
    run_migration_for_db(EstablishSaasTransactionDbConnection) do
      change_column_null :transaction_meta, :transaction_hash, null: false
      remove_index :transaction_meta, name: 'idx_lock_id'
      remove_index :transaction_meta, name: 'uk_tx_uuid'
      remove_column :transaction_meta, :lock_id
      remove_column :transaction_meta, :next_action_at
      remove_column :transaction_meta, :retry_count
      remove_column :transaction_meta, :status
    end
  end
end