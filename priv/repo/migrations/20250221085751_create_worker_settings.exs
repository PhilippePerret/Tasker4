defmodule Tasker.Repo.Migrations.CreateWorkerSettings do
  use Ecto.Migration

  def change do
    create table(:worker_settings, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :display_prefs, :map
      add :interaction_prefs, :map
      add :task_prefs, :map
      add :project_prefs, :map
      add :worktime_settings, :map
      add :worker_id, references(:workers, on_delete: :delete_all, type: :binary_id)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:worker_settings, [:worker_id])
  end
end
