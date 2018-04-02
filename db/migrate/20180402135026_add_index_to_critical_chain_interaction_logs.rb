class AddIndexToCriticalChainInteractionLogs < ActiveRecord::Migration[5.1]
  def up
    run_migration_for_db(EstablishCompanyBigDbConnection) do
      add_index :critical_chain_interaction_logs, [:transaction_hash], name: 'tx_hash', unique: true
    end
  end

  def down
    run_migration_for_db(EstablishCompanyBigDbConnection) do
      remove_index :critical_chain_interaction_logs, name: 'tx_hash'
    end
  end
end
