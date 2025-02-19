defmodule Tasker.Tache.TaskDependencies do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  @foreign_key_type :binary_id
  schema "task_dependencies" do
    belongs_to :before_task, Tasker.Tache.Task, foreign_key: :before_task_id
    belongs_to :after_task, Tasker.Tache.Task, foreign_key: :after_task_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(task_dependency, attrs) do
    task_dependency
    |> cast(attrs, [:before_task_id, :after_task_id])
    |> validate_required([:before_task_id, :after_task_id])
  end

end