defmodule Tasker.Projet.Project do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "projects" do
    field :title, :string
    field :details, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(project, attrs) do
    project
    |> cast(attrs, [:title, :details])
    |> validate_required([:title])
    |> validate_length(:title, min: 5, max: 255)
    |> unsafe_validate_unique(:title, Tasker.Repo)
    |> unique_constraint(:title)
  end
end
