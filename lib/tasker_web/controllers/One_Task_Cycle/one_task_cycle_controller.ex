defmodule TaskerWeb.OneTaskCycleController do
  use TaskerWeb, :controller

  import Ecto.{Query}
  alias Tasker.Repo

  alias Tasker.Projet
  alias Tasker.Tache.{Task, TaskSpec, TaskTime, TaskDependencies}
  # TaskNature
  alias Tasker.Tache

  @task_properties ["id", "title", "project_id"]
  @task_spec_properties ["details", "priority", "urgence", "difficulty", "notes"]
  @task_time_properties [
    "started_at", "ended_at", "should_start_at", "should_end_at", 
    "given_up_at", "recurrence", 
    "expect_duration", "execution_time", "deadline_trigger"]

  @now NaiveDateTime.utc_now()
  @bod NaiveDateTime.beginning_of_day(@now)

  def main(conn, _params) do
    candidates = get_candidate_tasks(conn.assigns.current_worker.id)
    if Enum.count(candidates) == 0 do
      conn
      |> put_flash(:error, dgettext("tasker", "You need at least one task to work on."))
      |> redirect(to: ~p"/tasks/new")
    else
      render(conn, :at_work, %{
        projects: projects_as_json_table(),
        natures: natures_as_json_table(),
        candidates: Jason.encode!(candidates),
        alertes: Jason.encode!(get_alerts(conn.assigns.current_worker.id))
      })
    end
  end


  defp projects_as_json_table do
    Projet.list_projects() 
    # |> IO.inspect(label: "Projets")
    |> Enum.reduce(%{}, fn p, accu -> 
      p = p 
      |> Map.from_struct()
      |> Map.delete(:__meta__) 
      # |> IO.inspect(label: "-projet")
      Map.put(accu, p.id, p)
    end)
    # |> IO.inspect(label: "Projets en table")
    |> Jason.encode!()
  end

  defp natures_as_json_table do
    Tache.list_natures()
    |> Enum.reduce(%{}, fn p, accu -> 
      p = p 
      |> Map.from_struct()
      |> Map.take([:id, :name]) 
      Map.put(accu, p.id, p)
    end)
    |> Jason.encode!()
  end

  @doc """
  Fonction qui relève les tâches dont une alerte doit être données
  au cours de la session (journée) courante
  """
  def get_alerts(worker_id) do
    sql = alerts_request()
    params = [Ecto.UUID.dump!(worker_id)] # Remplace par l'ID réel du worker
    result = Tasker.Repo.query!(sql, params)
    |> IO.inspect(label: "\nresult de requête alerts")
    result.rows
    |> Enum.map(fn row -> 
      Enum.zip(result.columns, row) 
      |> Map.new()
      |> (fn map ->
        %{task_id: Ecto.UUID.load!(map["id"]), title: map["title"], start: map["should_start_at"], alerts: map["alerts"]}
      end).()
    end)
    |> IO.inspect(label: "\ntasks_with_alert")
  end

  @doc """
  Function qui relève les tâches candidates pour la session et les
  retourne.

  @return {List of %Task{}} Liste des tâches retournées dans l'ordre
  "naturel", avec toutes les propriétés nécessaires à leur affichage
  et leur manipulation au cours de la session.
  """
  def get_candidate_tasks(worker_id) do
    sql = candidates_request()
    params = [Ecto.UUID.dump!(worker_id)] # Remplace par l'ID réel du worker
    result = Tasker.Repo.query!(sql, params)
    # |> IO.inspect(label: "RÉSULT")
    # raise "pour voir"
    tasks = result.rows
    |> Enum.map(fn row -> 
      Enum.zip(result.columns, row) 
      |> Map.new()
      |> (fn map ->
        # task = %Task{task_spec: %TaskSpec{},task_time: %TaskTime{}}
        task = %{task_spec: %{}, task_time: %{}}

        task =
        Enum.reduce(@task_properties, task, fn prop, collec -> 
          add_prop_and_value(collec, prop, map[prop], nil)
        end)

        task =
        Enum.reduce(@task_time_properties, task, fn prop, collec ->
          add_prop_and_value(collec, prop, map[prop], :task_time)
        end)

        # Dernier, retourné
        Enum.reduce(@task_spec_properties, task, fn prop, collec ->
          add_prop_and_value(collec, prop, map[prop], :task_spec)
        end)
      end).()
      # |> IO.inspect(label: "ROW")
    end)
    |> Enum.map(fn task -> 
      task = Map.put(task, :task_spec, struct(TaskSpec, task.task_spec))
      task = Map.put(task, :task_time, struct(TaskTime, task.task_time))
      struct(Task, task)
    end)
    # Filtre des tâches
    # -----------------
    # L'ajout a été inauguré pour supprimer les tâches récurrentes
    # passées et futures qui sont exclusives
    # 
    # Mais attention ! Une tâche récurrente dans le passé a dû voir
    # sa prochaine échéance mise dans le futur. Donc, en fait, ce 
    # qu'il convient d'exclure, ce sont toutes les tâches, passées et
    # futures, qui ne sont pas du jour courant.
    # 
    |> Enum.filter(fn task ->
      if task.task_spec.priority == 5 do
        # Il faut que ce soit une tâche du jour
        task_bod = NaiveDateTime.beginning_of_day(task.task_time.should_start_at)
        diff = NaiveDateTime.diff(@bod, task_bod, :hour) 
        tache_du_jour = diff == 0

        # Mais pas une tache excluvive terminée
        # Note : on prend la fin comme repère puisqu'on peut prendre 
        # une tâche exclusive en cours de route.
        tache_not_finite = NaiveDateTime.after?(task.task_time.should_end_at, @now)

        la_garder = tache_du_jour && tache_not_finite

        la_garder
      else true end
    end)
    # |> IO.inspect(label: "TÂCHES FINALES")

    # On récupère tous les ids de tâche pour récupérer les
    # dépendances
    task_ids = Enum.map(tasks, fn task -> task.id end)
    task_ids_binaires = Enum.map(task_ids, fn id -> Ecto.UUID.dump!(id) end)

    # On récupère toutes leurs dépendances
    query = from p in TaskDependencies,
      where: p.before_task_id in ^task_ids,
      group_by: p.before_task_id,
      select: %{before_task_id: p.before_task_id, after_task_ids: fragment("array_agg(?)", p.after_task_id)}
    dependances = Repo.all(query)
    |> Enum.reduce(%{}, fn task_deps, collec ->
      ids = task_deps.after_task_ids |> Enum.map(fn id -> Ecto.UUID.load!(id) end)
      Map.put(collec, task_deps.before_task_id, ids)
    end)
    # |> IO.inspect(label: "DÉPENDANCES")

    query =
    from nt in "tasks_natures",
      where: nt.task_id in ^task_ids_binaires,
      # group_by: nt.task_id #,
      select: {nt.task_id, nt.nature_id}
  
    natures = Repo.all(query)
    |> Enum.reduce(%{}, fn {tid, natid}, coll -> 
      tid = Ecto.UUID.load!(tid)
      list = Map.get(coll, tid, [])
      list = list ++ [natid]
      Map.put(coll, tid, list)
    end)
    # |> IO.inspect(label: "NATURES PAR TÂCHES")
    # raise "Pour voir les tâches"

    # Relève des scripts des tâches qui ont été retenues
    query = 
      from s in Tasker.ToolBox.TaskScript,
        join: tk in Task,
          on: s.task_id == tk.id,
        where: tk.id in ^task_ids,
        select: {tk.id, %{title: s.title, type: s.type, argument: s.argument}}
    
    scripts = Repo.all(query)
    |> Enum.reduce(%{}, fn {task_id, script}, coll ->
      scripts_task = coll[task_id] || []
      Map.put(coll, task_id, scripts_task ++ [script])
    end)

    # Relève des notes des tâches qui ont été retenues
    query =
      from n in Tasker.ToolBox.Note,
      join: nt in "notes_tasks", 
        on: n.id == nt.note_id,
      join: tsp in TaskSpec, 
        on: tsp.id == nt.task_spec_id,
      join: tk in Task, 
        on: tsp.task_id == tk.id,
      join: w in Tasker.Accounts.Worker, 
        on: n.author_id == w.id,
      where: tk.id in ^task_ids,
      select: %{task_id: tk.id, note: %{id: n.id, title: n.title, details: n.details, author: w.pseudo}}

    notes = Repo.all(query)
    |> Enum.reduce(%{}, fn data, coll ->
      notes_task = coll[data.task_id] || []
      Map.put(coll, data.task_id, notes_task ++ [data.note])
    end)

    # Une table des tâches pour mettre les dépendances
    # 
    # Note, ci-dessous, on peut faire %{task | ...} pour ajouter les
    # propriétés uniquement parce qu'elles ont été déclarées comme
    # champ virtuels dans le schéma de la tâche :
    #     field :notes, :map, virtual: true
    # 
    tasks = tasks
    |> Enum.map(fn task ->
      task = %{task | dependencies: dependances[task.id] }
      task = %{task | natures: Map.get(natures, task.id, nil)}
      task = %{task | scripts: Map.get(scripts, task.id, nil)}
      %{task | notes: Map.get(notes, task.id, nil)}
    end)
    # |> IO.inspect(label: "TÂCHES DÉFINITIVES -avant- CLASSEMENT")
    # raise "pour voir"
    
    # On tire ensuite une Map simple de la tâche %Task{}
    # en ne gardant que les propriétés utiles
    Tasker.TaskRankCalculator.sort(tasks)
    |> Enum.map(fn task -> 
      task = Map.from_struct(task) 
      task = Map.delete(task, :project)
      task = Map.delete(task, :__meta__)

      ttime = Map.from_struct(task.task_time)
      ttime = Map.delete(ttime, :task)
      ttime = Map.delete(ttime, :__meta__)
      task = %{task | task_time: ttime}

      tspec = Map.from_struct(task.task_spec)
      tspec = Map.delete(tspec, :task)
      tspec = Map.delete(tspec, :__meta__)
      task = %{task | task_spec: tspec}

      %{task | rank: Map.from_struct(task.rank)}
    end)
    # |> IO.inspect(label: "TÂCHES DÉFINITIVES -après- CLASSEMENT")
  end

  defp add_prop_and_value(task, prop, value, task_key) do
    is_a_id = prop == "id" or String.ends_with?(prop, "_id")
    value = cond do
      is_nil(value) -> nil
      is_a_id       -> Ecto.UUID.load!(value)
      true          -> value
    end
    receiver =
    if is_nil(task_key) do
      task
    else
      Map.get(task, task_key)
    end
    receiver = Map.put(receiver, String.to_atom(prop), value)
    if is_nil(task_key) do
      receiver # c'est la tâche
    else
      Map.put(task, task_key, receiver)
    end
    # |> IO.inspect(label: "Retourné par add_prop_and_value")
  end

  @doc """

  """
  def alerts_request do
    """
    SELECT tk.id, tk.title, tkt.should_start_at, tkt.alerts
    FROM tasks tk
    JOIN task_times tkt ON tkt.task_id = tk.id
    WHERE (
      tkt.should_start_at > NOW() 
    ) AND (    
      tkt.alert_at <= NOW() + INTERVAL '1 days'
    ) AND (
    -- S'il y a un worker défini, il faut que ce soit le courant
      NOT EXISTS (SELECT 1 FROM tasks_workers tw WHERE tw.task_id = tk.id)
      OR EXISTS (SELECT 1 FROM tasks_workers tw WHERE tw.task_id = tk.id AND tw.worker_id = $1)
    )
    ;
    """
  end

  def candidates_request do
    """
    SELECT tks.*, tkt.*, tk.*
    FROM tasks tk
    JOIN task_specs tks ON tks.task_id = tk.id
    JOIN task_times tkt ON tkt.task_id = tk.id
    WHERE (
      tkt.should_start_at IS NULL 
      OR tkt.should_start_at <= NOW() + INTERVAL '7 days'
      ) AND NOT EXISTS (
        SELECT 1 FROM task_dependencies td
        WHERE td.after_task_id = tk.id
      ) AND (
        NOT EXISTS (SELECT 1 FROM tasks_workers tw WHERE tw.task_id = tk.id)
        OR EXISTS (SELECT 1 FROM tasks_workers tw WHERE tw.task_id = tk.id AND tw.worker_id = $1)
      )
    ORDER BY 
      CASE 
        WHEN should_start_at IS NULL AND should_end_at IS NULL THEN '9999-12-31'::date
        ELSE LEAST(should_start_at, should_end_at)
      END
    ;
    """
  end
end