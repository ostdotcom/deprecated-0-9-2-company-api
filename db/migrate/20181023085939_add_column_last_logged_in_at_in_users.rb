class AddColumnLastLoggedInAtInUsers < DbMigrationConnection

  def up
    run_migration_for_db(EstablishCompanyUserDbConnection) do
      add_column :users, :last_logged_in_at, :integer, null: true, after: :status
    end
  end

  def down
    run_migration_for_db(EstablishCompanyUserDbConnection) do
      remove_column :users, :last_logged_in_at
    end
  end

end
