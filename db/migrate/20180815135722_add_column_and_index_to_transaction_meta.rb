class AddColumnAndIndexToTransactionMeta < DbMigrationConnection

  def up

    client = Client.first
    if client.blank?

      createChainIdColumnWithoutDefaultValue

    else
      client_id = client.id

      r = SaasApi::OnBoarding::FetchChainInteractionParams.new.perform({client_id: client_id})

      if !r.success? || r.data['utility_chain_id'].blank?

        createChainIdColumnWithoutDefaultValue

      else

        createChainIdColumnWithDefaultValue(r.data['utility_chain_id'])

      end
    end

  end

  def down
    run_migration_for_db(EstablishSaasTransactionDbConnection) do

      remove_index :transaction_meta, name: 'uniq_transaction_hash_chain_id'

      remove_column :transaction_meta, :chain_id

      add_index :transaction_meta, [:transaction_hash], name: 'uniq_transaction_hash', unique: true

    end

  end

  def createChainIdColumnWithDefaultValue(chainIdDefaultValue)
    run_migration_for_db(EstablishSaasTransactionDbConnection) do

      add_column :transaction_meta, :chain_id, :integer, after: :id, null: false, default: chainIdDefaultValue

      remove_index :transaction_meta, name: 'uniq_transaction_hash'

      add_index :transaction_meta, [:transaction_hash, :chain_id], name: 'uniq_transaction_hash_chain_id', unique: true

    end
  end

  def createChainIdColumnWithoutDefaultValue
    run_migration_for_db(EstablishSaasTransactionDbConnection) do

      add_column :transaction_meta, :chain_id, :integer, after: :id, null: false

      remove_index :transaction_meta, name: 'uniq_transaction_hash'

      add_index :transaction_meta, [:transaction_hash, :chain_id], name: 'uniq_transaction_hash_chain_id', unique: true

    end
  end
end