defmodule Tasker.Projet.Project do
  use Ecto.Schema
  import Ecto.Changeset
  use Gettext, backend: TaskerWeb.Gettext

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "projects" do
    field :title, :string
    field :details, :string
    field :folder, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(project, attrs) do
    project
    |> cast(attrs, [:title, :details, :folder])
    |> validate_required([:title])
    |> validate_length(:title, min: 2, max: 50)
    |> unsafe_validate_unique(:title, Tasker.Repo)
    |> unique_constraint(:title)
    |> validate_folder_exists()
  end

  defp validate_folder_exists(changeset) do
    folder_path = get_change(changeset, :folder, changeset.data.folder)
    cond do
      is_binary(folder_path) and not String.starts_with?(folder_path, "/") ->
        add_error(changeset, :folder, dgettext("tasker", "The project folder must be an absolute path."))  
      is_binary(folder_path) and not File.exists?(folder_path) ->
        add_error(changeset, :folder, dgettext("tasker", "The project folder ‘%{path}’ could not be found.", path: folder_path))
      true -> changeset
    end
  end

end
