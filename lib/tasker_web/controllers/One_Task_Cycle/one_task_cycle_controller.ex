defmodule TaskerWeb.OneTaskCycleController do
  use TaskerWeb, :controller

  import Ecto.Query

  alias Tasker.Projet
  # alias Tasker.Tache.{Task, TaskSpec, TaskTime}


  def main(conn, _params) do
    render(conn, :main_panel, %{
      projects:   Projet.list_projects(),
      candidates: get_candidate_tasks()
    })
  end

  @doc """
  Function qui relève les tâches candidates pour la session et les
  retourne.

  @return {List of %Task{}} Liste des tâches retournées dans l'ordre
  "naturel", avec toutes les propriétés nécessaires à leur affichage
  et leur manipulation au cours de la session.
  """
  def get_candidate_tasks do
    []
  end

  def candidates_request do
    """
    SELECT tk.*, tks.*, tkt.*
    FROM tasks tk
    JOIN task_specs tks ON tks.task_id = tk.id
    JOIN task_times tkt ON tkt.task_id = tk.id
    WHERE ???
    ORDER BY tkt.should_start_at
    ;
    """
  end
end