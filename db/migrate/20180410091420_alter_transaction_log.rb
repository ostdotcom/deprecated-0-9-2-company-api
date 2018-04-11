class AlterTransactionLog < DbMigrationConnection

  def up
    run_migration_for_db(EstablishSaasTransactionDbConnection) do
      query = "ALTER TABLE transaction_logs \
                ADD COLUMN `transaction_type` TINYINT(4) NULL AFTER `client_token_id`,\
                ADD COLUMN `block_number` BIGINT NULL AFTER `input_params`,\
                ADD COLUMN `gas_price` BIGINT NULL AFTER `input_params`,\
                ADD COLUMN `gas_used` INT NULL AFTER `input_params`,\
                ADD COLUMN `error_code` INT NULL AFTER `formatted_receipt`\
                ; "
      EstablishSaasTransactionDbConnection.connection.execute(query)
    end
  end

  def down
    run_migration_for_db(EstablishSaasTransactionDbConnection) do
      remove_column :transaction_logs, :transaction_type
      remove_column :transaction_logs, :block_number
      remove_column :transaction_logs, :gas_price
      remove_column :transaction_logs, :gas_used
      remove_column :transaction_logs, :error_code
    end
  end

end
