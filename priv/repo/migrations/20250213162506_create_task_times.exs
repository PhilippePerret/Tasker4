defmodule Tasker.Repo.Migrations.CreateTaskTimes do
  use Ecto.Migration

  def change do
    create table(:task_times, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :should_start_at, :naive_datetime
      add :should_end_at, :naive_datetime
      add :imperative_end, :boolean, default: false
      add :started_at, :naive_datetime
      add :ended_at, :naive_datetime
      add :alert_at, :naive_datetime
      add :alerts, {:array, :map}, default: nil
      add :given_up_at, :naive_datetime
      add :recurrence, :string
      add :expect_duration, :integer
      add :execution_time, :integer
      add :task_id, references(:tasks, on_delete: :delete_all, type: :binary_id)
      add :deadline_trigger, :boolean, default: true

      timestamps(type: :utc_datetime)
    end

    create index(:task_times, [:task_id])
  end
end
