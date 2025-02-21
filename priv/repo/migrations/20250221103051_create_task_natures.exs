defmodule Tasker.Repo.Migrations.CreateTaskNatures do
  use Ecto.Migration

  def change do
    create table(:task_natures, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string

      timestamps(type: :utc_datetime)
    end

    create table(:tasks_natures) do
      add :task_id, references(:tasks, on_delete: :delete_all, type: :binary_id)
      add :nature_id, references(:task_natures, on_delete: :delete_all, type: :binary_id)
    
      timestamps()
    end
    
    create unique_index(:tasks_natures, [:task_id, :nature_id])

  end
end
