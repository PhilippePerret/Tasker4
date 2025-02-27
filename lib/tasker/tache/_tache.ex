defmodule Tasker.Tache do
  @moduledoc """
  The Tache context.
  """
  import Ecto.Query, warn: false
  alias Tasker.Repo

  alias Tasker.Tache.{Task, TaskSpec, TaskTime, TaskNature, TaskDependencies, TasksWorkers}

  @now NaiveDateTime.utc_now()
  
  @doc """
  Returns the list of tasks.

  ## Examples

      iex> list_tasks()
      [%Task{}, ...]

  """
  def list_tasks do
    Repo.all(Task)
  end

  @doc """
  """
  def list_natures do
    Repo.all(TaskNature)
  end

  @doc """
  Gets a single task.

  Raises `Ecto.NoResultsError` if the Task does not exist.

  ## Examples

      iex> get_task!(123)
      %Task{}

      iex> get_task!(456)
      ** (Ecto.NoResultsError)

  """
  def get_task!(id) do
    Repo.get!(Task, id)
    |> Repo.preload(task_spec: [:notes])
    |> Repo.preload(:task_time)
    |> Repo.preload(:natures)
    |> Map.put(:dependencies, get_dependencies(id))
  end

  @doc """
  Function qui crée une dépendance entre les deux tâches.
  Note : pour les tests uniquement, pour le moment
  @api

  @param {%Task{}}  task_before La tâche avant (dont la suivante dépend)
  @param {%Task{}}  task_after  La tâche dépendante de la précédente
  """
  def create_dependency(task_before, task_after) do
    data = %{
      before_task_id: task_before.id, 
      after_task_id:  task_after.id,
    }
    TaskDependencies.changeset(%TaskDependencies{}, data)
    |> Repo.insert!()
  end

  @doc """
  Associe la tâche aux natures fournie

  @return %Task{} La tâche avec ses natures associées
  """
  def inject_natures(task, natures) when is_list(natures) do
    task_id_bin = Ecto.UUID.dump!(task.id)
    task_natures = natures
    |> Enum.map(fn nature ->
      %{task_id: task_id_bin, nature_id: nature}
    end)
    Repo.insert_all("tasks_natures", task_natures)
    get_task!(task.id)
  end
  def define_natures(task, nature) when is_binary(nature), do: define_natures(task, [nature])

  @doc """
  @api
  Fonction pour assigner la tâche à un worker. On peut l'assigner
  soit par sa structure soit par son identifiant.
  """
  def assign_to(%Task{} = task, worker_id) when is_binary(worker_id) do
    data_assoc = %{
      task_id: task.id,
      worker_id: worker_id,
      assigned_at: NaiveDateTime.utc_now()
    }
    TasksWorkers.changeset(%TasksWorkers{}, data_assoc)
    |> Repo.insert!()
  end
  def assign_to(%Task{} = task, %Tasker.Accounts.Worker{} = worker) do
    assign_to(task, worker.id)
  end

  @doc """
  @api
  Fonction qui relève et retourne les dépendances de la tâche d'id
  +task_id+

  @return {Map} Une table avec :tasks_after (liste des tâches 
  dépendantes) et :tasks_before (idem).
  Chaque élément de la liste est une {Map} qui définit : 
    :id       {String} Identifiant binaire de la tâche
    :title    {String} Son titre
    :details  {String} Les 500 premiers caractères de son détail.
  """
  def get_dependencies(task_id) do
    task_id = Ecto.UUID.dump!(task_id)

    sql_after = """
    SELECT t.id, t.title, LEFT(ts.details, 500)
    FROM task_dependencies td 
    JOIN tasks t ON t.id = td.after_task_id
    JOIN task_specs ts ON ts.task_id = td.after_task_id
    WHERE td.before_task_id = $1
    ;
    """
    dependencies = get_dependencies(%{}, task_id, sql_after, :tasks_after)

    sql_before = """
    SELECT t.id, t.title, LEFT(ts.details, 500)
    FROM task_dependencies td 
    JOIN tasks t ON t.id = td.before_task_id
    JOIN task_specs ts ON ts.task_id = td.before_task_id
    WHERE td.after_task_id = $1
    ;
    """
    get_dependencies(dependencies, task_id, sql_before, :tasks_before)
    # |> IO.inspect(label: "\nDEPENDANCES")
  end

  defp get_dependencies(deps_map, task_id, sql, key) when is_binary(sql) do
    tasks = 
      case Ecto.Adapters.SQL.query(Tasker.Repo, sql, [task_id]) do
        {:ok, postgrex_result} -> task_list_from_postgrex_result(postgrex_result)
        {:error, exception} -> IO.puts(:stderr, exception); []
      end
    Map.put(deps_map, key, tasks)
  end

  defp task_list_from_postgrex_result(result) do
    result.rows 
    |> Enum.map(fn [id, title, details] -> 
      %{
        id: Ecto.UUID.load!(id), 
        title: title, 
        details: details
      }
    end)
  end

  @doc """
  Creates a task.

  ## Examples

      iex> create_task(%{title: "Une très bonne valeur"})
      {:ok, %Task{}}

      iex> create_task(%{mauvais_champ: "x"})
      {:error, %Ecto.Changeset{}}

  """
  def create_task(attrs \\ %{}) do
    res = %Task{} |> Task.changeset(attrs) |> Repo.insert()
    case res do
    {:ok, task} ->
      %TaskSpec{} |> TaskSpec.changeset(%{task_id: task.id}) |> Repo.insert!()
      %TaskTime{} |> TaskTime.changeset(%{task_id: task.id}) |> Repo.insert!()
      res
    {:error, _} -> 
      res
    end
  end

  @doc """
  Updates a task.

  ## Examples

      iex> update_task(task, %{field: new_value})
      {:ok, %Task{}}

      iex> update_task(task, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_task(%Task{} = task, attrs) do
    task
    |> Task.changeset(attrs)
    # |> IO.inspect(label: "\nAprès changeset dans update_task")
    |> Repo.update()
  end

  @doc """
  Deletes a task.

  ## Examples

      iex> delete_task(task)
      {:ok, %Task{}}

      iex> delete_task(task)
      {:error, %Ecto.Changeset{}}

  """
  def delete_task(%Task{} = task) do
    Repo.delete(task)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking task changes.

  ## Examples

      iex> change_task(task)
      %Ecto.Changeset{data: %Task{}}

  """
  def change_task(%Task{} = task, attrs \\ %{}) do
    Task.changeset(task, attrs)
  end


  @doc """
  Retourne true si la tâche est du jour, false dans le cas contraire.

  # Examples

    iex> today?(F.create_task(headline: @now, deadline: nil))
    true

    iex> today?(F.create_task(headline: @now, deadline: NaiveDateTime.add(@now, 1000)))
    true

    iex> today?(F.create_task(headline: @now, deadline: :near_future))
    false

    iex> today?(F.create_task(headline: :far_future))
    false

    iex> today?(F.create_task(headline: :near_past))
    false

  """
  @today_start NaiveDateTime.beginning_of_day(@now)
  @today_end   NaiveDateTime.end_of_day(@now)
  def today?(%Task{} = task) do
    ttime = task.task_time
    task_start  = ttime.should_start_at
    task_end    = ttime.should_end_at
    (!is_nil(task_start) and NaiveDateTime.after?(task_start, @today_start)) \
    and (!is_nil(task_start) and NaiveDateTime.before?(task_start, @today_end)) \
    and (is_nil(task_end) or NaiveDateTime.before?(task_end, @today_end))
  end




  alias Tasker.Tache.TaskSpec

  @doc """
  Returns the list of task_specs.

  ## Examples

      iex> list_task_specs()
      [%TaskSpec{}, ...]

  """
  def list_task_specs do
    Repo.all(TaskSpec)
  end

  @doc """
  Gets a single task_spec.

  Raises `Ecto.NoResultsError` if the Task spec does not exist.

  ## Examples

      iex> get_task_spec!(123)
      %TaskSpec{}

      iex> get_task_spec!(456)
      ** (Ecto.NoResultsError)

  """
  def get_task_spec!(id) do 
    Repo.get!(TaskSpec, id)
    |> Repo.preload(:notes)
  end

  @doc """
  Creates a task_spec.

  ## Examples

      iex> create_task_spec(%{field: value})
      {:ok, %TaskSpec{}}

      iex> create_task_spec(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_task_spec(attrs \\ %{}) do
    %TaskSpec{}
    |> TaskSpec.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a task_spec.

  ## Examples

      iex> update_task_spec(task_spec, %{field: new_value})
      {:ok, %TaskSpec{}}

      iex> update_task_spec(task_spec, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_task_spec(%TaskSpec{} = task_spec, attrs) do
    task_spec
    |> TaskSpec.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a task_spec.

  ## Examples

      iex> delete_task_spec(task_spec)
      {:ok, %TaskSpec{}}

      iex> delete_task_spec(task_spec)
      {:error, %Ecto.Changeset{}}

  """
  def delete_task_spec(%TaskSpec{} = task_spec) do
    Repo.delete(task_spec)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking task_spec changes.

  ## Examples

      iex> change_task_spec(task_spec)
      %Ecto.Changeset{data: %TaskSpec{}}

  """
  def change_task_spec(%TaskSpec{} = task_spec, attrs \\ %{}) do
    TaskSpec.changeset(task_spec, attrs)
  end

  def get_task_spec_by_task_id(task_id) do
    Repo.one(from ts in TaskSpec, where: ts.task_id == ^task_id)
  end
  def get_task_spec_by_task_id!(task_id) do
    Repo.one!(from ts in TaskSpec, where: ts.task_id == ^task_id)
  end

  alias Tasker.Tache.TaskTime

  @doc """
  Returns the list of task_times.

  ## Examples

      iex> list_task_times()
      [%TaskTime{}, ...]

  """
  def list_task_times do
    Repo.all(TaskTime)
  end

  @doc """
  Gets a single task_time.

  Raises `Ecto.NoResultsError` if the Task time does not exist.

  ## Examples

      iex> get_task_time!(123)
      %TaskTime{}

      iex> get_task_time!(456)
      ** (Ecto.NoResultsError)

  """
  def get_task_time!(id), do: Repo.get!(TaskTime, id)

  @doc """
  Creates a task_time.

  ## Examples

      iex> create_task_time(%{field: value})
      {:ok, %TaskTime{}}

      iex> create_task_time(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_task_time(attrs \\ %{}) do
    %TaskTime{}
    |> TaskTime.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a task_time.

  ## Examples

      iex> update_task_time(task_time, %{field: new_value})
      {:ok, %TaskTime{}}

      iex> update_task_time(task_time, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_task_time(%TaskTime{} = task_time, attrs) do
    task_time
    |> TaskTime.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a task_time.

  ## Examples

      iex> delete_task_time(task_time)
      {:ok, %TaskTime{}}

      iex> delete_task_time(task_time)
      {:error, %Ecto.Changeset{}}

  """
  def delete_task_time(%TaskTime{} = task_time) do
    Repo.delete(task_time)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking task_time changes.

  ## Examples

      iex> change_task_time(task_time)
      %Ecto.Changeset{data: %TaskTime{}}

  """
  def change_task_time(%TaskTime{} = task_time, attrs \\ %{}) do
    TaskTime.changeset(task_time, attrs)
  end
end
