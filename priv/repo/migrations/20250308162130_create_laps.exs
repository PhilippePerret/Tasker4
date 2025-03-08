defmodule Tasker.Repo.Migrations.CreateLaps do
  use Ecto.Migration

  def change do
    create table(:laps, primary_key: false) do
      add :start, :naive_datetime
      add :stop, :naive_datetime
      add :task_id, references(:tasks, on_delete: :delete_all, type: :binary_id)
    end

    create index(:laps, [:task_id])
  end
end
