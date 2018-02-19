class CreateTransactionLogs < DbMigrationConnection
  def up

    run_migration_for_db(EstablishSaasTransactionDbConnection) do

      add_column :transaction_logs, :client_id, :integer, after: :id
      add_column :transaction_logs, :client_token_id, :integer, after: :client_id
      add_column :transaction_logs, :formatted_receipt, :string, after: :input_params

      rename_column :transaction_logs, :uuid, :transaction_uuid
      rename_column :transaction_logs, :chain, :chain_type
      rename_column :transaction_logs, :params, :input_params

      add_index :transaction_logs, [:transaction_uuid], name: 'index_1', unique: true

    end

  end

  def down

    run_migration_for_db(EstablishSaasTransactionDbConnection) do

      remove_column :transaction_logs, :client_id
      remove_column :transaction_logs, :client_token_id

      rename_column :transaction_logs, :transaction_uuid, :uuid
      rename_column :transaction_logs, :chain_type, :chain
      rename_column :transaction_logs, :input_params, :params

      remove_index :transaction_logs, name: 'index_1'

    end

  end

end
