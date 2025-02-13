defmodule Tasker.Tache.Task do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "tasks" do

    field :title, :string
    belongs_to :project, Tasker.Projet.Project, type: :binary_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(task, attrs) do
    task
    |> cast(attrs, [:title, :project_id])
    |> validate_required([:title])
    |> validate_length(:title, min: 10, max: 255)
  end
end
