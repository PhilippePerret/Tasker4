defmodule Tasker.Tache.TaskNature do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "task_natures" do
    field :name, :string
    many_to_many :tasks, Tasker.Tache.Task, join_through: "tasks_natures"

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(task_nature, attrs) do
    task_nature
    |> cast(attrs, [:name])
    |> unique_constraint(:name)
    |> validate_required([:name])
  end
end
