class AddColumnAndIndexToTransactionMeta < DbMigrationConnection

  def up

    client = Client.first
    client_id = client.id

    r = SaasApi::OnBoarding::FetchChainInteractionParams.new.perform({client_id: client_id})
    fail 'chain id not found' unless r.success?

    utility_chain_id = r.data['utility_chain_id']

    run_migration_for_db(EstablishSaasTransactionDbConnection) do

      add_column :transaction_meta, :chain_id, :integer, after: :id, null: false, default: utility_chain_id

      remove_index :transaction_meta, name: 'uniq_transaction_hash'

      add_index :transaction_meta, [:transaction_hash, :chain_id], name: 'uniq_transaction_hash_chain_id', unique: true

    end

  end

  def down
    run_migration_for_db(EstablishSaasTransactionDbConnection) do

      remove_index :transaction_meta, name: 'uniq_transaction_hash_chain_id'

      remove_column :transaction_meta, :chain_id

      add_index :transaction_meta, [:transaction_hash], name: 'uniq_transaction_hash', unique: true

    end

  end

end
