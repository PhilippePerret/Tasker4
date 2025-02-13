defmodule Tasker.Tache.TaskTime do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "task_times" do
    field :priority, :integer
    field :started_at, :naive_datetime
    field :should_start_at, :naive_datetime
    field :should_end_at, :naive_datetime
    field :ended_at, :naive_datetime
    field :given_up_at, :naive_datetime
    field :urgence, :integer
    field :recurrence, :string
    field :expect_duration, :integer
    field :execution_time, :integer
    belongs_to :task, Tasker.Tache.Task

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(task_time, attrs) do
    task_time
    |> cast(attrs, [:task_id, :should_start_at, :should_end_at, :started_at, :ended_at, :given_up_at, :priority, :urgence, :recurrence, :expect_duration, :execution_time])
    |> validate_required([:task_id])
  end
end
