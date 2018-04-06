class CreateWhitelistedEmails < DbMigrationConnection

  def up
    run_migration_for_db(EstablishCompanyUserDbConnection) do
      create_table :whitelisted_emails do |t|
        t.string :email, null: false
        t.timestamps
      end
    end
  end

  def down
    run_migration_for_db(EstablishCompanyUserDbConnection) do
      drop_table :whitelisted_emails
    end
  end

end
