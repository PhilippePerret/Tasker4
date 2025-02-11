defmodule Tasker.Repo.Migrations.CreateWorkers do
  use Ecto.Migration

  def change do
    create table(:workers, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :pseudo, :string
      add :email, :string
      add :password, :string

      timestamps(type: :utc_datetime)
    end
  end
end
