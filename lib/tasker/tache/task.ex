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
    field :rank, :map, virtual: true
    many_to_many :natures, 
      Tasker.Tache.TaskNature, 
      join_through: "tasks_natures",
      on_replace: :delete,
      join_keys: [task_id: :id, nature_id: :id]

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(task, attrs) do
    task 
    |> cast(attrs, [:title, :project_id])
    |> put_assoc(:natures, Map.get(attrs, "natures", []))
    |> cast_assoc(:task_spec)
    |> cast_assoc(:task_time)
    |> validate_required([:title])
    |> validate_length(:title, min: 10, max: 255)
  end

  
end
