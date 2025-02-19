defmodule TaskerWeb.ToolsController do
  use TaskerWeb, :controller

  @doc """
  Appelée pour jouer un script.
  Le nom du script (script_name) est automatiquement tiré du nom de
  la route. Les paramètres envoyés doivent contenir "script_args",
  même vide.
  """
  def run_script(
      conn, 
      %{"script" => script_name, "script_args" => script_args} = params
    ) 
    do 
    IO.inspect(params, label: "PARAMS")

    retour = run(script_name, script_args)
    conn
    |> json(retour)
    |> halt()
  end

  def run("create_note", args) do
    
    IO.inspect(args, label: "avec les arguments")
    Map.merge(%{note: args}, %{ok: true, error: nil})
  end

  @doc """
  Récupération de la liste des tâches avant ou après une date de
  référence.
  @param {Map} args Paramètres
  @param {String} args.type 'next' ou 'prev' pour dire les tâches 
                            avant ou après la date de référence.
  @param {String} args.date_ref La date de référence (ou nil)
  """
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

  def run("save_task_relations", args) do
    # TODO
    %{
      ok: false, 
      error: "Je dois apprendre à sauver les relations.",
      previous: [], # liste des tâches précédentes de la tâche courante
      next: []      # Idemp pour les suivantes
    }
  end


  defp requete_task_list_prev_or_next(args, nil) do
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
  defp requete_task_list_prev_or_next(args, date_ref) do
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