defmodule Tasker.TaskRankCalculator do

  alias Tasker.Tache
  alias Tasker.Tache.{Task, TaskRank}

  @now NaiveDateTime.utc_now()

  @weights %{
    priority:           %{weight:   100_000,    time_factor: 7.5},
    urgence:            %{weight:   50_000,     time_factor: 7.5},
    # Le poids de l'expiration (headline dans le passé et non 
    # démarrée) est ajouté à chaque minute : remoteness * weigth
    deadline_expired:   %{weight:       1,      time_factor: nil},
    headline_expired:   %{weight:     0.5,      time_factor: nil},
    # Une tâche du jour (commence aujourd'hui et fini aujourd'hui 
    # ou non défini)
    today_task:         %{weight:     250,      time_factor: nil},
    # Une tâche sans échéance (ni headline ni deadline) qui a été
    # commencé
    started_long_ago:   %{weight:     200,      time_factor: 0.001},
    # Une tâche accomplie à 90 %
    almost_finished:    %{weight:     250,      time_factor: nil}
  }
  @weight_keys Map.keys(@weights)

  # Pour les tests
  def weights, do: @weights

  @doc """
  Fonction principale qui reçoit une liste de tache (Task) et les
  classe par task_rank avant de les envoyer au client pour usage.
  @main
  @api

  ## Examples

    iex> RCalc.sort([])
    []

  @param {List of %Task{}} task_list Liste des structures Task.
  """
  def sort(task_list) when is_list(task_list) do
    task_list
    |> Enum.map(&calc_task_rank(&1))
    |> Enum.sort_by(&(&1.rank.value))
    |> Enum.with_index()
    |> Enum.map(fn {task, index} -> set_rank(task, :index, index) end)
  end

  @doc """
  Fonction qui calcule le task_rank d'une tâche et le retourne.

  # Examples

    iex> task = RCalc.calc_task_rank(F.create_task())
    iex> not is_nil(task)
    true

  @param {Task} task    Une tâche à exécuter
  @return {Task} La tâche avec son rank calculé
  """
  def calc_task_rank(%Task{} = task) do
    %{ task | rank: %TaskRank{} }
    |> calc_remoteness()
    |> add_weights()
  end

  @doc """
  Function qui calcule l'éloignement de la tâche par rapport à au-
  jourd'hui. Cet éloignement peut être :
  - positif => la tâche est dans le futur
  - 0 => la tâche est actuelle (démarée ou headline passé et deadine future)
  - nil => la tâche n'a pas de temps définis
  - négatif => la tâche est dans le passé

  ## Examples

    - Avec une headline dans le futur proche
    iex> task = RCalc.calc_remoteness(F.create_task(headline: :near_future, rank: true))
    iex> task.rank.remoteness > 0
    true

    - Avec une deadline dans le proche passé
    iex> task = RCalc.calc_remoteness(F.create_task(deadline: :near_past, rank: true))
    iex> task.rank.remoteness > 0
    true

    - Avec une tâche démarrée
    iex> task = RCalc.calc_remoteness(F.create_task(started: :near_past, rank: true))
    iex> task.rank.remoteness == 0
    assert(task.rank.remoteness == 0)

    - Avec une tâche dont l'headline est dépassée
    iex> task = RCalc.calc_remoteness(F.create_task(headline: :near_past, rank: true))
    iex> task.rank.remoteness > 0
    true

    - Test avec des dates précises
    iex> headline = NaiveDateTime.add(@now, @day, :minute)
    iex> task = RCalc.calc_remoteness(F.create_task(headline: headline, rank: true))
    iex> assert_in_delta(task.rank.remoteness, @day, 5)
    true

    iex> headline = NaiveDateTime.add(@now, -@day, :minute)
    iex> task = RCalc.calc_remoteness(F.create_task(headline: headline, rank: true))
    iex> assert_in_delta(task.rank.remoteness, @day / 4, 5)
    true

    iex> deadline = NaiveDateTime.add(@now, @day, :minute)
    iex> task = RCalc.calc_remoteness(F.create_task(deadline: deadline, rank: true))
    iex> assert_in_delta(task.rank.remoteness, @day / 2, 5)
    true


    - Avec une tâche sans échéance et non démarrée
    iex> task = RCalc.calc_remoteness(F.create_task(rank: true))
    iex> is_nil(task.rank.remoteness)
    true

    - Une tâche plus lointaine a un remoteness plus grand
    iex> task1 = RCalc.calc_remoteness(F.create_task(headline: :near_future, rank: true))
    iex> task2 = RCalc.calc_remoteness(F.create_task(headline: :far_future, rank: true))
    iex> task1.rank.remoteness < task2.rank.remoteness
    true


  @return %Task{} dont on a calculé le remoteness mis dans task.rank.remoteness
  """
  def calc_remoteness(task) do
    is_started  = !is_nil(task.task_time.started_at)
    headline    = task.task_time.should_start_at
    deadline    = task.task_time.should_end_at
    now = NaiveDateTime.utc_now()

    should_start_after_now  = headline && NaiveDateTime.compare(headline, now) == :gt
    should_start_before_now = headline && NaiveDateTime.compare(headline, now) == :lt
    should_end_after_now    = deadline && NaiveDateTime.compare(deadline, now) == :gt
    should_end_before_now   = deadline && NaiveDateTime.compare(deadline, now) == :lt
    
    remoteness =
    cond do
      is_started -> 0
      should_end_before_now   -> NaiveDateTime.diff(now, deadline, :minute)
      should_start_before_now -> NaiveDateTime.diff(now, headline, :minute) / 4 # on rapproche beaucoup, quand la headline est dépassée
      should_end_after_now    -> NaiveDateTime.diff(deadline, now, :minute) / 2 # on rapproche, quand c'est la deadline
      should_start_after_now  -> NaiveDateTime.diff(headline, now, :minute)
      true -> nil
    end
    # IO.inspect(remoteness, label: "\nREMOTENESS")
    set_rank(task, :remoteness, remoteness)
  end

  defp add_weights(task) do
    @weight_keys
    |> Enum.reduce(task, fn key, tk -> add_weight(tk, key) end)
  end

  @doc """
  FonctionS ajoutant le poids à la tâche suivant la propriété définie

  @param {%Task} task La tâche concernée
  @param {Atom} property  La propriété de poids

  @return {%Task} La tâche concernée, avec dans son :rank la valeur
  de poids ajoutée.
  """
  def add_weight(task, :headline_expired = prop) do
    ttime = task.task_time
    if !is_nil(ttime.should_start_at) and is_nil(ttime.started_at) do
      if is_nil(task.rank.remoteness) do
        raise "remoteness ne devrait pas pouvoir être nil avec should_end_at à #{task.task_time.should_end_at}"
      end
      weight = task.rank.remoteness * @weights[prop].weight
      set_rank(task, :value, task.rank.value + weight)
    else task end
  end
  def add_weight(task, :deadline_expired = prop) do
    ttime = task.task_time
    if is_nil(ttime.should_start_at) and !is_nil(ttime.should_end_at) and is_nil(ttime.started_at) do
      if is_nil(task.rank.remoteness) do
        raise "remoteness ne devrait pas pouvoir être nil avec should_end_at à #{ttime.should_end_at}"
      end
      weight = task.rank.remoteness * @weights[prop].weight
      set_rank(task, :value, task.rank.value + weight)
    else task end
  end

  def add_weight(task, :today_task) do
    if Tache.today?(task) do
      set_rank(task, :value, task.rank.value + @weights[:today_task].weight)
    else task end
  end

  # Tâche presque achevée
  def add_weight(task, :almost_finished = key) do
    ttime = task.task_time
    duree = ttime.expect_duration # durée espérée
    execu = ttime.execution_time  # temps d'exécution déjà effectué
    cond do
      is_nil(ttime.started_at) -> task
      is_nil(duree) or is_nil(execu) -> task
      (execu < duree * 90 / 100) -> task
      true ->
        set_rank(task, :value, task.rank.value + @weights[key].weight)
    end
  end


  # Fonction qui ajoute du poids quand la tâche, sans échéance, a été
  # démarrée. Plus elle a été démarrée il y a longtemps et plus le
  # poids est élevée.
  # Attention : pour une tâche concernée, le remoteness est à 0, 
  # puisque le remoteness ne compte que l'éloignement d'une tâche non
  # démarée
  def add_weight(task, :started_long_ago = key) do
    ttime = task.task_time
    if is_nil(ttime.should_start_at) and is_nil(ttime.should_end_at) and (!is_nil(ttime.started_at)) do
      start_remoteness = NaiveDateTime.diff(@now, ttime.started_at, :minute)
      time_emphasis = start_remoteness * @weights[key].time_factor
      poids = @weights[key].weight * time_emphasis
      set_rank(task, :value, task.rank.value + poids)
    else task end
  end

  def add_weight(task, key) when is_atom(key) do
    poids = Map.get(task.task_time, key) || 0
    poids = poids * @weights[key].weight * time_ponderation(task, key)
    set_rank(task, :value, task.rank.value + poids)
  end

  defp time_ponderation(task, key) do
    # IO.puts "-> time_ponderation(key=#{inspect key}) / factor: #{@weights[key].time_factor} / remoteness: #{inspect task.rank.remoteness}"
    cond do
      is_nil(task.rank.remoteness)  -> 1
      task.rank.remoteness == 0     -> 1
      @weights[key].time_factor > 0 -> 
        @weights[key].time_factor / task.rank.remoteness
        # |> IO.inspect(label: "[key=#{inspect key}/factor=#{@weights[key].time_factor}/remoteness=#{inspect task.rank.remoteness}] Pondération de")
      true                          -> 1
    end
  end

  defp set_rank(task, key, value) do
    value = (key == :value) && round(value) || value
    %{task | rank: %{task.rank | key => value }}
  end
end