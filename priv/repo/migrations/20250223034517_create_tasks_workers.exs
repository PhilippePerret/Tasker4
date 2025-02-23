defmodule Tasker.Repo.Migrations.CreateTasksWorkers do
  use Ecto.Migration

  def change do
    create table(:tasks_workers, primary_key: false) do
      add :task_id, references(:tasks, on_delete: :delete_all, type: :binary_id)
      add :worker_id, references(:workers, on_delete: :delete_all, type: :binary_id)
      add :assigned_at, :utc_datetime, default: fragment("now()")
    end

    create index(:tasks_workers, [:task_id])
    create index(:tasks_workers, [:worker_id])
  end
end
