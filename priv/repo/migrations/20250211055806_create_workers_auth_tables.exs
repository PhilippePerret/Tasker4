defmodule Tasker.Repo.Migrations.CreateWorkersAuthTables do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS citext", ""

    create table(:workers, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :pseudo, :string, null: false
      add :email, :citext, null: false
      add :hashed_password, :string, null: false
      add :confirmed_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create unique_index(:workers, [:email])

    create table(:workers_tokens, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :worker_id, references(:workers, type: :binary_id, on_delete: :delete_all), null: false
      add :token, :binary, null: false
      add :context, :string, null: false
      add :sent_to, :string

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:workers_tokens, [:worker_id])
    create unique_index(:workers_tokens, [:context, :token])
  end
end
