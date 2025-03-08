defmodule TaskerWeb.TasksOpController do
  use TaskerWeb, :controller

  import Ecto.Query

  alias Tasker.{Repo, Tache}
  alias Tasker.Tache.TaskDependencies

  @doc """
  Fonction centralisée pour recevoir toutes les opérations à faire 
  sur les tâches; aussi bien au niveau de l'enregistrement que de la
  relève.
  """
  def exec_operation(conn, %{"op" => operation} = params) do
    retour = exec_op(operation, params)
    conn
    |> json(retour)
    |> halt()
  end


  # defp uuid(uuid_str), do: Ecto.UUID.dump!(uuid_str)

  @doc """
  L'opération proprement dit, à exécuter sur la ou les tâches.
  Chacune de ces fonctions doit impérativement retourner une table
  de résultat d'opération qui contient au moins :ok à true (succès)
  ou false (échec) avec dans ce cas un message d'erreur consigné dans
  :error.

  @param {String} foo L'opération, qui sert de guard
  @param {Map} params.relations Définit toutes les relations qu'en-
                tretient la tâche avec les autres tâches (aussi bien
                celles avant qu'après)
  """
  def exec_op("save_relations", %{"relations" => relations, "task_id" => task_id}) do
    case Repo.transaction(fn ->
      delete_all_dependencies_of(task_id)
      update_all_dependencies_with(relations)
    end) do
      {_nombre_rows, _} -> 
        %{ok: true, dependencies: Tache.get_dependencies(task_id)}
      {:error, exception} -> 
        IO.puts(:stderr, exception)
        %{ok: false, error: "Erreur SQL"}  
    end
  end

  def exec_op("save_working_time", %{"laps" => laps, "task_id" => task_id}) do
    IO.puts "Je dois enregistrer le temps de la tâche #{task_id} avec : #{inspect laps}"
    start = Helper.mseconds_to_naive(laps["start"])
    stop  = Helper.mseconds_to_naive(laps["stop"])
    %{ok: true}
  end


  defp delete_all_dependencies_of(task_id) do
    # task_id = uuid(task_id)
    from(td in TaskDependencies, 
      where: td.before_task_id == ^task_id or td.after_task_id == ^task_id
    ) |> Repo.delete_all()
  end

  defp update_all_dependencies_with(relations) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    temp_map = %{inserted_at: now, updated_at: now}
    new_relations = relations
      |> Enum.map(fn [id_before, id_after] -> 
          Map.merge(temp_map, %{before_task_id: id_before, after_task_id: id_after})
        end)
    Repo.insert_all(TaskDependencies, new_relations)
  end


end