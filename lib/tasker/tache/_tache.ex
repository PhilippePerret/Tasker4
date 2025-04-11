defmodule Tasker.Tache do
  @moduledoc """
  The Tache context.
  """
  import Ecto.Query, warn: false
  alias Tasker.Repo

  alias Tasker.Tache.{Task, TaskSpec, TaskTime, TaskNature, TaskDependencies, TasksWorkers}
  alias Tasker.ToolBox

  @now NaiveDateTime.utc_now()
  
  @doc """
  Fonction qui reçoit un idenfiant de tâche et la retourne, complète,
  c'est-à-dire avec tous ces éléments, times, notes, scripts, natures, 
  etc. sous la forme d'une Map qui peut être transformée en JSON.

  @param {String} task_id

  @return {Map} Table des données de la tâche
  """
  def full_task_as_json_table(task_id) do
    task = get_task!(task_id)

    task =
    [:__struct__, :__meta__, :project_id]
    |> Enum.reduce(task, fn key, task -> 
      Map.delete(task, key)
    end)
    
    common_extra_keys = [:__struct__, :__meta__, :task_id, :task, :inserted_at, :updated_at]
    
    task_spec =
    common_extra_keys 
    |> Enum.reduce(task.task_spec, fn key, task_spec -> 
      Map.delete(task_spec, key)
    end)
    task_time =
    common_extra_keys 
    |> Enum.reduce(task.task_time, fn key, task_time -> 
      Map.delete(task_time, key)
    end)

    project = if is_nil(task.project) do nil else
      common_extra_keys 
      |> Enum.reduce(task.project, fn key, project -> 
        Map.delete(project, key)
      end)
    end

    # Les natures sont des structures Natures
    # Pour le moment, on les remplaces par les {:id, :name}
    natures = task.natures
    |> Enum.map(fn nature ->
      %{id: nature.id, name: nature.name}
    end)

    # Les scripts sont sous forme string, même quand il n'y en a pas
    scripts = JSON.decode!(task.scripts)
    
    task
    |> Map.put(:task_spec,  task_spec)
    |> Map.put(:task_time,  task_time)
    |> Map.put(:project,    project)
    |> Map.put(:natures,    natures)
    |> Map.put(:scripts,    scripts)
    |> IO.inspect(label: "task fin")
    # raise "pour voir"
    
  end

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
    |> Repo.preload(:project)
    |> Repo.preload(task_spec: [notes: [:author]])
    |> Repo.preload(:task_time)
    |> Repo.preload(:natures)
    |> Map.put(:scripts, get_task_scripts(id, :as_json))
    |> Map.put(:dependencies, get_dependencies(id))
  end

  @doc """
  Function qui crée une dépendance entre les deux tâches.
  Note : pour les tests uniquement, pour le moment
  @api

  @param {%Task{}}  task_before La tâche avant (dont la suivante dépend)
  @param {%Task{}}  task_after  La tâche dépendante de la précédente

  @return La tâche avant avec ses dépendances
  """
  def create_dependency(task_before, task_after) when is_struct(task_before, Task) do
    create_dependency(task_before.id, task_after)
  end
  def create_dependency(task_before, task_after) when is_struct(task_after, Task) do
    create_dependency(task_before, task_after.id)
  end
  def create_dependency(tbefore_id, tafter_id) when is_binary(tbefore_id) and is_binary(tafter_id) do
    data = %{ before_task_id: tbefore_id, after_task_id:  tafter_id }

    # Repo.all(TaskDependencies)
    # |> IO.inspect(label: "Toutes les dépendances")
    # IO.inspect(data, label: "Dépendance à ajouter")

    TaskDependencies.changeset(%TaskDependencies{}, data)
    |> Repo.insert!()

    get_task!(tbefore_id)
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

  @return %Task{} La tâche qu'on a assignée
  """
  def assign_to(%Task{} = task, worker_id) when is_binary(worker_id) do
    data_assoc = %{
      task_id: task.id,
      worker_id: worker_id,
      assigned_at: NaiveDateTime.utc_now()
    }
    TasksWorkers.changeset(%TasksWorkers{}, data_assoc)
    |> Repo.insert!()

    task
  end
  def assign_to(%Task{} = task, %Tasker.Accounts.Worker{} = worker) do
    assign_to(task, worker.id)
  end

  @doc """
  Fonction qui relève les scripts de la tâche d'identifiant +task_id+

  @return {List} La liste des données scripts
  """
  def get_task_scripts(task_id) do
    query = from s in Tasker.ToolBox.TaskScript, 
              where: s.task_id == ^task_id
    Repo.all(query)
    # |> IO.inspect(label: "Scripts relevés")
  end
  def get_task_scripts(task_id, :as_json) do
    get_task_scripts(task_id)
    |> Enum.map(fn script ->
      %{
        id: script.id, 
        title: script.title,
        type: script.type,
        argument: script.argument
      }
    end)
    |> Jason.encode!()
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
  Destruction d'une tâche (avec la tâche ou son identifiant binaire)

  ## Examples

      iex> delete_task(task)
      {:ok, %Task{}}

      iex> delete_task(task)
      {:error, %Ecto.Changeset{}}

  """
  def delete_task(foo, options \\ [])
  def delete_task(%Task{} = task, options) do
    Repo.delete(task, options)
  end
  def delete_task(task_id, options) when is_binary(task_id) do
    Repo.delete(get_task!(task_id), options)
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
  Archivage de la tâche.

  Attention au cas spécial : une tâche récurrente. Dans ce cas-là,
  on crée une instance pour archive, mais on ne détruit pas la tâche,
  qu'on va au contraire updater pour quelle trouve sa prochaine 
  itération.

  """
  def archive_task(%Task{} = task) do
    code_json = code_archive_task(task)
    File.write!(archive_path(), code_json <> "\n", [:create, :append])
  end
  defp code_archive_task(task) do
    data = Map.from_struct(task)
    Map.merge(data, %{
      project:    Map.delete(Map.from_struct(task.project), :__meta__),
      task_time:  Map.drop(Map.from_struct(task.task_time), [:__meta__, :task]),
      task_spec:  Map.drop(Map.from_struct(task.task_spec), [:__meta__, :task])
    })
    |> Map.drop([:__meta__])
    # On supprime toutes les données vides à l'intérieur des maps
    |> Enum.reduce(%{}, fn {key, value}, coll -> 
      if Enumerable.impl_for(value) do
        IO.inspect(value, label: "Value avant réduction")
        new_value = Enum.reduce(value, %{}, &reduit/2 )
        |> IO.inspect(label: "Nouvelle valeur")
        Map.put(coll, key, new_value)
      else coll end
    end)
    # On filtre seulement les données non vides/nulles/etc.
    |> Enum.reduce(%{}, fn {key, value}, coll ->
      if (is_nil(value) or is_empty?(value) or is_nullish?(value)) do
        coll
      else
        Map.put(coll, key, value)
      end
    end)
    # |> IO.inspect(label: "DONNÉES ARCHIVES")
    |> Map.merge(%{app_version: Tasker.version(), date: NaiveDateTime.utc_now()})
    # |> IO.inspect(label: "DONNÉES FINALES ARCHIVES")
    |> Jason.encode!()
    # |> IO.inspect(label: "Données Jsonées")
  end
  defp archive_path do
    Path.join([:code.priv_dir(:tasker), "archives", "tasks.dat"])
  end

  defp is_empty?(foo) when is_list(foo) or is_map(foo) do
    if Enumerable.impl_for(foo) do
      Enum.empty?(foo)
    else false end
  end
  # Dans tous les autres cas
  defp is_empty?(_foo), do: false

  @nullish_values ["[]", "nil", "null", "{}"]
  defp is_nullish?(foo) when is_binary(foo) do
    Enum.member?(@nullish_values, foo)
  end
  defp is_nullish?(_foo), do: false


  def reduit(map, collector) when is_map(map) do
    map =
    if Enumerable.impl_for(map) do
      map
    else
      Map.from_struct(map) 
      |> Map.delete(:__meta__)
      |> Map.delete(:tasks) # pour les natures ou les autres relations many-to-many
    end
    map 
    |> Enum.reduce(collector, &reduit/2 )
  end
  def reduit({key, value}, collector) when is_atom(key) do
    if (is_nil(value) or is_empty?(value) or is_nullish?(value)) do
      collector
    else
      Map.put(collector, key, value)
    end
  end
  def reduit(foo, _collector) do
    raise "Je ne sais pas réduire #{inspect foo}"
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
  def update_task_time(%TaskTime{} = task_time, attrs \\ %{}) do
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

  @doc """
  Actualisation de la durée d'exécution de la tâche.

  Rappel : la durée d'exécution de la tâche est constitué de la 
  somme de tous les 'laps' {Tasker.ToolBox.Laps} enregistrés
  pour le task_time de la tâche.

  @param {Binary} task_id Identifiant de la tâche
  
  @return {Integer} Le nombre de minutes correspondant au temps où la
  tâche a été jouée.
  """
  def update_execution_time(task_id) when is_binary(task_id) do
    
    query = 
    from laps in ToolBox.Laps,
      where: laps.task_id == ^task_id,
      select: %{start: laps.start, stop: laps.stop}

    ex_time =
    Repo.all(query)
    |> Enum.reduce(0, fn row, x -> 
      x + NaiveDateTime.diff(row.stop, row.start)
    end)

    # Transformer les secondes accumulées en minutes
    ex_time = round(ex_time / 60)

    # Actualiser
    query =
      from tt in TaskTime,
      where: tt.task_id == ^task_id,
      update: [set: [execution_time: ^ex_time ]]

      Repo.update_all(query, [])

    # Retourner le temps d'exécutation total
    ex_time
  end

end
