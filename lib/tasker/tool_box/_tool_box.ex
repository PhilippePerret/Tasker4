defmodule Tasker.ToolBox do

  import Ecto.Query, warn: false
  alias Tasker.Repo

  alias Tasker.Tache.{NoteTaskSpec}

  alias Tasker.ToolBox.{Note, Laps, TaskScript}


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

    {:ok, note} =
    %Note{}
    |> Note.changeset(attrs)
    |> Repo.insert()

    # Associer la note à la task_spec via la table de jointure
    Repo.insert!(%NoteTaskSpec{note_id: note.id, task_spec_id: task_spec.id})

    {:ok, note}
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
  # La même que précédente, mais en envoyant juste les attributs de
  # la note, donc bien sûr +id+ qui permettra de récupérer la note
  def update_note(attrs) when is_map(attrs) do
    get_note!(attrs["id"]||attrs[:id])
    |> update_note(attrs)
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

  # === LAPS ====
  # Les temps de travail d'une tâche

  def create_laps(attrs \\ %{}) do
    Laps.changeset(%Laps{}, attrs)
    |> Repo.insert!()
  end

  # ========= SCRIPTS DE TÂCHE =============

  def create_task_script(attrs \\ %{}) do
    TaskScript.changeset(%TaskScript{}, attrs)
    |> Repo.insert!()
  end

  def delete_script(%TaskScript{} = script) do
    Repo.delete(script)
  end
  def delete_script(script_id) when is_binary(script_id) do
    query = from s in TaskScript, where: s.id == ^script_id
    Repo.delete(query)
  end
  def delete_scripts(ids) when is_list(ids) do
    IO.inspect(ids, label: "List des ids")
    query = from s in TaskScript, where: s.id in ^ids
    Repo.delete_all(query)
  end
  
end