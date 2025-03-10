defmodule TaskerWeb.OneTaskCycleController do
  use TaskerWeb, :controller

  import Ecto.{Query}
  alias Tasker.Repo

  alias Tasker.Projet
  alias Tasker.Tache.{Task, TaskSpec, TaskTime, TaskNature, TaskDependencies}

  @task_properties ["id", "title", "project_id"]
  @task_spec_properties ["details", "difficulty", "notes"]
  @task_time_properties [
    "started_at", "ended_at", "should_start_at", "should_end_at", 
    "given_up_at", "priority", "urgence", "recurrence", 
    "expect_duration", "execution_time", "deadline_trigger"]


  def main(conn, _params) do
    render(conn, :main_panel, %{
      projects: projects_as_json_table(),
      candidates: Jason.encode!(get_candidate_tasks(conn.assigns.current_worker.id))
    })
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

    # Une table des tâches pour mettre les dépendances
    tasks = tasks
    |> Enum.map(fn task ->
      task = %{task | dependencies: dependances[task.id] }
      %{task | natures: Map.get(natures, task.id, nil)}
    end)
    # |> IO.inspect(label: "TÂCHES DÉFINITIVES -avant- CLASSEMENT")
    # raise "pour voir"
    
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