defmodule Tasker.Repo.Migrations.CreateTaskScripts do
  use Ecto.Migration

  def change do
    create table(:task_scripts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :title, :string
      add :type, :string
      add :argument, :text
      add :task_id, references(:tasks, on_delete: :delete_all, type: :binary_id)
    end

    create index(:task_scripts, [:task_id])
  end
end
