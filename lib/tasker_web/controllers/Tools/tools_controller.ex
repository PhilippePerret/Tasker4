defmodule TaskerWeb.ToolsController do
  use TaskerWeb, :controller

  alias Tasker.ToolBox

  @doc """
  Pour remplacer les clés {String} par des clés {Atom} dans la map
  +map+
  """
  def atomize(map) when is_map(map) do
    Enum.reduce(map, %{}, fn {key, value}, accu ->
      Map.put(accu, String.to_atom(key), value)
    end)
  end

  @doc """
  Appelée pour jouer un script.
  Le nom du script (script_name) est automatiquement tiré du nom de
  la route. Les paramètres envoyés doivent contenir "script_args",
  même vide.

  ATTENTION : Les "scripts" dont il est question ici n'ont rien à 
  voir avec les "scripts de tâche" qui, eux, sont gérés par le module
  Tache.task_script.ex
  """
  def run_script(
      conn, 
      %{"script" => script_name, "script_args" => script_args} = _params
    ) do 
    # IO.inspect(params, label: "PARAMS")
    # IO.inspect(conn, label: "CONN data")

    script_args = Map.put(script_args, "worker_id", conn.assigns.current_worker.id)

    retour = run(script_name, script_args)
    conn
    |> json(retour)
    |> halt()
  end

  @doc """
  Fonction générique 'run' qui permet de jouer tous les outils utiles
  pour la gestions de ces outils.

  @return {Map} Le retour à renvoyer au serveur, avec obligatoirement
  la clé :ok à True en cas de succès et à False en cas d'échec, en 
  renseignant :error avec l'erreur rencontrée.
  """

  # Enregistrement des notes
  def run("save_note", args) do
    args = atomize(args)
    args = Map.put(args, :author_id, args.worker_id)
    # |> IO.inspect(label: "Arguments pour note")
    if args[:id] == "" do
      # Création de la note
      case ToolBox.create_note(args) do
      {:ok, note} -> %{note: ToolBox.get_note!(note.id), ok: true}
      {:error, err} -> %{note: nil, ok: false, error: err}
      end
    else
      # Update de la note
      case ToolBox.update_note(args) do
      {:ok, note} -> %{note: note, ok: true}
      {:error, err} -> %{note: nil, ok: false, error: err}
      end
    end
  end

  # Suppression d'une note
  #
  # Note : elle doit être supprimée 1) dans la table des notes et 2) dans la table des associations avec les tâches.
  def run("remove_note", args) do
    note_id = args["note_id"]
    case ToolBox.delete_note(note_id) do
    {:ok, _} -> 
      %{ok: true}
    {:error, changeset} ->
      IO.inspect(changeset, label: "Impossible de détruire la note")
      %{ok: false, error: "Problème à la destruction de la note (consulter la consoler serveur)."}
    end
  end

  # Récupération de la liste des tâches 
  # (avant ou après une date de référence.)
  # @param {Map} args Paramètres
  # @param {String} args.type 'next' ou 'prev' pour dire les tâches 
                            # avant ou après la date de référence.
  # @param {String} args.date_ref La date de référence (ou nil)
  def run("get_task_list", args) do
    date_ref = args["date_ref"]
    date_ref = 
    case NaiveDateTime.from_iso8601(date_ref) do
      {:error, :invalid_format} -> nil
      {:ok, dref} -> dref
    end
    task_id = args["task_id"] && Ecto.UUID.dump!(args["task_id"])
    proj_id = Ecto.UUID.dump!(args["project_id"])
    # Relève des tâches dans la base
    sql = requete_task_list_prev_or_next(args, date_ref)
    params = is_nil(date_ref) && [proj_id, task_id] || [proj_id, task_id, date_ref]
    case Tasker.Repo.query(sql, params) do
      {:ok, %Postgrex.Result{columns: cols, rows: rows}} ->
        # liste = Enum.map(rows, &Enum.zip(cols, &1))
        # liste = Enum.map(rows, &Tuple.to_list/1)
        liste = [cols | Enum.map(rows, &Enum.to_list/1)]
        %{ok: true, tasks: liste, args: args}
      {:error, reason} -> 
        IO.inspect(reason, label: "\nRAISON ERREUR ECTO")
        %{ok: false, error: reason.message || reason.postgres}
    end
  end

  defp requete_task_list_prev_or_next(_args, nil) do
    """
    SELECT t.id::text, t.title, tt.should_start_at, tt.should_end_at, LEFT(ts.details, 500) AS details
    FROM tasks t
    JOIN task_times tt ON tt.task_id = t.id
    JOIN task_specs ts ON ts.task_id = t.id
    WHERE t.project_id = $1 AND t.id <> $2
    ORDER BY 
      CASE 
        WHEN tt.should_start_at IS NOT NULL THEN tt.should_start_at
        WHEN tt.should_end_at IS NOT NULL THEN tt.should_end_at
        ELSE NULL
      END ASC;
    """
  end
  # +date_ref+ ne sert à rien d'autre ici qu'à faire un guard 
  # différent lorsqu'aucune date n'est définie.
  defp requete_task_list_prev_or_next(args, _date_ref) do
    [dref, dother] = (args["position"] == "prev") && ["tt.should_start_at", "tt.should_end_at"] || ["tt.should_end_at", "tt.should_start_at"]
    """
    SELECT t.id::text, t.title, tt.should_start_at, tt.should_end_at, LEFT(ts.details, 500) AS details
    FROM tasks t
    JOIN task_times tt ON tt.task_id = t.id
    JOIN task_specs ts ON ts.task_id = t.id
    WHERE t.project_id = $1
    AND t.id <> $2
    AND (
      (#{dref} IS NOT NULL AND #{dref} < $3::timestamp) OR
      (#{dref} IS NULL AND #{dother} IS NOT NULL AND #{dother} < $3::timestamp) OR
      (#{dref} IS NULL AND #{dother} IS NULL)
    )
    ORDER BY 
      CASE 
        WHEN tt.should_start_at IS NOT NULL THEN tt.should_start_at
        WHEN tt.should_end_at IS NOT NULL THEN tt.should_end_at
        ELSE NULL
      END ASC;
    """
  end

end