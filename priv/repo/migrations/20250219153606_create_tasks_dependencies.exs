defmodule Tasker.Repo.Migrations.CreateTasksDependencies do
  use Ecto.Migration

  def change do
    create table(:tasks_dependencies, primary_key: false) do
      add :before_task_id, references(:tasks, on_delete: :delete_all, type: :binary_id)
      add :after_task_id, references(:tasks, on_delete: :delete_all, type: :binary_id)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:tasks_dependencies, [:before_task_id, :after_task_id])
    create index(:tasks_dependencies, [:before_task_id])
    create index(:tasks_dependencies, [:after_task_id])
  
  end
end
