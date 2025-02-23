defmodule Tasker.Tache.TasksWorkers do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  @foreign_key_type :binary_id
  schema "tasks_workers" do
    belongs_to :task, Tasker.Tache.Task, foreign_key: :task_id
    belongs_to :worker, Tasker.Accounts.Worker, foreign_key: :worker_id
    field :assigned_at, :utc_datetime
  end

  @doc false
  def changeset(tasks_workers, attrs) do
    tasks_workers
    |> cast(attrs, [:task_id, :worker_id])
    |> validate_required([:task_id, :worker_id])
  end
end
