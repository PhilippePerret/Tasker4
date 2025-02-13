defmodule Tasker.Tache.Task do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "tasks" do

    field :title, :string
    belongs_to :project, Tasker.Projet.Project, type: :binary_id
    has_one :task_spec, Tasker.Tache.TaskSpec
    has_one :task_time, Tasker.Tache.TaskTime

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(task, attrs) do
    task
    |> cast(attrs, [:title, :project_id])
    |> cast_assoc(:task_spec)
    |> cast_assoc(:task_time)
    |> validate_required([:title])
    |> validate_length(:title, min: 10, max: 255)
  end
end
