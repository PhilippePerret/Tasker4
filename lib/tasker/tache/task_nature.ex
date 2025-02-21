defmodule Tasker.Tache.TaskNature do
  use Ecto.Schema
  import Ecto.Changeset

  @foreign_key_type :binary_id
  @primary_key {:id, :string, autogenerate: false}
  schema "task_natures" do
    field :name, :string
    many_to_many :tasks, Tasker.Tache.Task, join_through: "tasks_natures"

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(task_nature, attrs) do
    task_nature
    |> cast(attrs, [:name, :id])
    |> unique_constraint(:name)
    |> validate_required([:name])
  end
end
