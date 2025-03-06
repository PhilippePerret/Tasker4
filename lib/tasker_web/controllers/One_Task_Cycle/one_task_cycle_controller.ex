defmodule TaskerWeb.OneTaskCycleController do
  use TaskerWeb, :controller

  # import Ecto.Query

  alias Tasker.Projet
  alias Tasker.Tache.{Task, TaskSpec, TaskTime}


  def main(conn, params) do
    IO.inspect(conn, label: "conn")
    render(conn, :main_panel, %{
      projects:   Projet.list_projects(),
      candidates: Jason.encode!(get_candidate_tasks(conn.assigns.current_worker.id))
    })
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
    |> IO.inspect(label: "RÉSULT")
    # raise "pour voir"
    result.rows
    |> Enum.map(fn row -> 
      Enum.zip(result.columns, row) 
      |> Map.new()
      |> (fn map ->
        %Task{
          id: Ecto.UUID.load!(map["id"]),
          title: map["title"],
          task_spec: %TaskSpec{},
          task_time: %TaskTime{}
        }
      end).()
      |> IO.inspect(label: "ROW")
    end)
    raise "pour voir"
    # |> Tasker.TaskRankCalculator.sort()
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