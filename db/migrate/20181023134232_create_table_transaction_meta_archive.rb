class CreateTableTransactionMetaArchive < DbMigrationConnection
  def up
    run_migration_for_db(EstablishSaasTransactionDbConnection) do
      query = "CREATE TABLE transaction_meta_archive as \
                SELECT * FROM transaction_meta \
                where 1 = 2 \
                ;"
      EstablishSaasTransactionDbConnection.connection.execute(query)
    end
  end
  def down
    query = "DROP TABLE IF EXISTS transaction_meta_archive \
                ;"
    EstablishSaasTransactionDbConnection.connection.execute(query)
  end
end