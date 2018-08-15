class AddColumnAndIndexToTransactionMeta < DbMigrationConnection
  def up
    run_migration_for_db(EstablishSaasTransactionDbConnection) do

      add_column :transaction_meta, :chain_id, :integer, after: :id

      remove_index :transaction_meta, name: 'uniq_transaction_hash'

      add_index :transaction_meta, [:chain_id, :transaction_hash], name: 'uniq_chain_id_transaction_hash', unique: true

    end
  end

  def down
    run_migration_for_db(EstablishSaasTransactionDbConnection) do

      remove_index :transaction_meta, name: 'uniq_chain_id_transaction_hash'

      add_index :transaction_meta, [:transaction_hash], name: 'uniq_transaction_hash', unique: true

      remove_column :transaction_meta, :chain_id

    end
  end
end