class AddColumnAndIndexToCriticalChainInteractionLogs < DbMigrationConnection
  def up
    run_migration_for_db(EstablishCompanyBigDbConnection) do

      add_column :critical_chain_interaction_logs, :chain_id, :integer, after: :id

      remove_index :critical_chain_interaction_logs, name: 'tx_hash'

      add_index :critical_chain_interaction_logs, [:chain_id, :transaction_hash], name: 'chain_id_tx_hash', unique: true

    end
  end

  def down

    run_migration_for_db(EstablishCompanyBigDbConnection) do

      remove_index :critical_chain_interaction_logs, name: 'chain_id_tx_hash'

      add_index :critical_chain_interaction_logs, [:transaction_hash], name: 'tx_hash', unique: true

      remove_column :critical_chain_interaction_logs, :chain_id

    end

  end

end
