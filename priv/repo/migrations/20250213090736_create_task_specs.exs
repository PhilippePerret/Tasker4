defmodule Tasker.Repo.Migrations.CreateTaskSpecs do
  use Ecto.Migration

  def change do
    create table(:task_specs, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :details, :text
      add :difficulty, :integer, default: nil
      add :task_id, references(:tasks, on_delete: :delete_all, type: :binary_id)

      timestamps(type: :utc_datetime)
    end

    create index(:task_specs, [:task_id])
  end
end
