defmodule Tasker.Repo.Migrations.CreateTasks do
  use Ecto.Migration

  def change do
    create table(:tasks, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :title, :string
      add :project_id, references(:projects, on_delete: :delete_all, type: :binary_id)

      timestamps(type: :utc_datetime)
    end

    create index(:tasks, [:title])
    create index(:tasks, [:project_id])
  end
end
