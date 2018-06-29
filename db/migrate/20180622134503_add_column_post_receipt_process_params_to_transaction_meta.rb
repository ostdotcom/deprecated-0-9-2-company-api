class AddColumnPostReceiptProcessParamsToTransactionMeta < DbMigrationConnection

  def up

    run_migration_for_db(EstablishSaasTransactionDbConnection) do

      add_column :transaction_meta, :post_receipt_process_params, :text, :null => true, :after => :kind

    end

  end

  def down

    run_migration_for_db(EstablishSaasTransactionDbConnection) do

      remove_column :transaction_meta, :post_receipt_process_params

    end

  end

end
