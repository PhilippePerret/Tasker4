defmodule Tasker.ToolBox do

  import Ecto.Query, warn: false
  alias Tasker.Repo

  alias Tasker.Tache.{Task, TaskSpec}
  alias Tasker.ToolBox.Note


  @doc """
  Retourne la liste des notes

  ## Exemples

    iex> list_notes
    [%Note{}, ....]

  """
  def list_notes do
    Repo.all(Note)
  end

  @doc """
  Pour obtenir une simple note

  # Examples

    iex> get_note!(123)
    %Note{}

    iex> get_note!(456)
    ** (Ecto.NoResultsError)

  """
  def get_note!(id), do: Repo.get!(Note, id)
  
  @doc """
  Pour créer une note

  ## Examples

    iex> create_note(%{title: "Mon titre de note"})
    {:ok, %Note{}}

    iex> create_note(%{title: "aa"})
    {:error, %Ecto.Changeset{}}

  """
  def create_note(attrs \\ %{}) do
    task_spec = Tasker.Tache.get_task_spec!(attrs.task_spec_id)

    %Note{}
    |> Ecto.build_assoc(task_spec, :notes)
    |> Note.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Actualiser la note

  ## Example

    iex> update_note(note, %{title: "Le nouveau titre"})
    {:ok, %Note{}}

    iex> update_note(note, %{title: "bb"})
    {:error, %Ecto.Changeset{}}

  """
  def update_note(%Note{} = note, attrs) do
    note
    |> Note.changeset(attrs)
    |> Repo.update
  end


  @doc """
  Détruit une note

  ## Examples

      iex> delete_note(note)
      {:ok, %Note{}}

      iex> delete_note(note)
      {:error, %Ecto.Changeset{}}

  """
  def delete_note(%Note{} = note) do
    Repo.delete(note)
  end


  @doc """
  Retourne un `%Ecto.Changeset{}` pour traquer les changements dans
  la note

  ## Examples

      iex> change_note(note)
      %Ecto.Changeset{data: %Note{}}

  """
  def change_note(%Note{} = note, attrs \\ %{}) do
    Note.changeset(note, attrs)
  end

end