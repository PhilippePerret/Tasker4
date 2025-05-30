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
  def get_note!(id) do 
    Repo.get!(Note, id)
    |> Repo.preload(:author)
  end
  
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
    case Repo.insert(%NoteTaskSpec{note_id: note.id, task_spec_id: task_spec.id}) do
    {:ok, _} -> {:ok, note}
    {:error, changeset} ->
      IO.inspect(changeset, label: "Association Tâche-Note impossible")
      {:error, "Impossible d'associer la note à la tâche (consulter la console)"} 
    end
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

  À la destruction, il faut détruire la note et son association avec 
  la tâche (par sa TaskSpec)

  ## Examples

      iex> delete_note(note)
      {:ok, %Note{}}

      iex> delete_note(note)
      {:error, %Ecto.Changeset{}}

  """
  def delete_note(%Note{} = note) do
    note_id = Ecto.UUID.dump!(note.id)
    case Repo.delete_all(from asso in "notes_tasks", where: asso.note_id == ^note_id) do
    {1, _} -> Repo.delete(note)
    {:error, changeset} -> {:error, changeset}
    end
  end
  def delete_note(note_id) when is_binary(note_id) do
    delete_note(get_note!(note_id))
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

  def get_script!(script_id) do
    Repo.get!(TaskScript, script_id)
  end

  def create_task_script(attrs \\ %{}) do
    TaskScript.changeset(%TaskScript{}, attrs)
    |> Repo.insert!()
  end

  def update_task_script(attrs) do
    script = get_script!(attrs.id)
    TaskScript.changeset(script, attrs)
    |> Repo.update!()
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