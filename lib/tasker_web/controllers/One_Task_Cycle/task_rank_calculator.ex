defmodule Tasker.TaskRankCalculator do

  alias Tasker.Tache.{Task, TaskRank}

  @doc """
  Fonction principale qui reçoit une liste de tache (Task) et les
  classe par task_rank avant de les envoyer au client pour usage.
  @main
  @api

  ## Examples

    iex> RankCalc.sort([])
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

    iex> task = RankCalc.calc_task_rank(F.create_task())
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

  @weights %{
    priority:   %{weight: 100_000,  time_factor: 2},
    urgence:    %{weight: 50_000,   time_factor: 2}
  }

  @doc """
  Function qui calcule l'éloignement de la tâche par rapport à au-
  jourd'hui. Cet éloignement peut être :
  - positif => la tâche est dans le futur
  - 0 => la tâche est actuelle (démarée ou headline passé et deadine future)
  - nil => la tâche n'a pas de temps définis
  - négatif => la tâche est dans le passé

  ## Examples

    - Avec une headline dans le futur proche
    iex> task = RankCalc.calc_remoteness(F.create_task(headline: :near_future, rank: true))
    iex> task.rank.remoteness > 0
    true

    - Avec une deadline dans le proche passé
    iex> task = RankCalc.calc_remoteness(F.create_task(deadline: :near_past, rank: true))
    iex> task.rank.remoteness > 0
    true

    - Avec une tâche démarrée
    iex> task = RankCalc.calc_remoteness(F.create_task(started: :near_past, rank: true))
    iex> task.rank.remoteness == 0
    assert(task.rank.remoteness == 0)

    - Avec une tâche dont l'headline est dépassée
    iex> task = RankCalc.calc_remoteness(F.create_task(headline: :near_past, rank: true))
    iex> task.rank.remoteness > 0
    true

    - Test avec des dates précises
    iex> headline = NaiveDateTime.add(@now, @day, :minute)
    iex> task = RankCalc.calc_remoteness(F.create_task(headline: headline, rank: true))
    iex> assert_in_delta(task.rank.remoteness, @day, 5)
    true

    iex> headline = NaiveDateTime.add(@now, -@day, :minute)
    iex> task = RankCalc.calc_remoteness(F.create_task(headline: headline, rank: true))
    iex> assert_in_delta(task.rank.remoteness, @day / 4, 5)
    true

    iex> deadline = NaiveDateTime.add(@now, @day, :minute)
    iex> task = RankCalc.calc_remoteness(F.create_task(deadline: deadline, rank: true))
    iex> assert_in_delta(task.rank.remoteness, @day / 2, 5)
    true


    - Avec une tâche sans échéance et non démarrée
    iex> task = RankCalc.calc_remoteness(F.create_task(rank: true))
    iex> is_nil(task.rank.remoteness)
    true

    - Une tâche plus lointaine a un remoteness plus grand
    iex> task1 = RankCalc.calc_remoteness(F.create_task(headline: :near_future, rank: true))
    iex> task2 = RankCalc.calc_remoteness(F.create_task(headline: :far_future, rank: true))
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
      should_start_after_now  -> NaiveDateTime.diff(headline, now, :minute)
      should_start_before_now -> NaiveDateTime.diff(now, headline, :minute) / 4 # on rapproche beaucoup, quand la headline est dépassée
      should_end_after_now    -> NaiveDateTime.diff(deadline, now, :minute) / 2 # on rapproche, quand c'est la deadline
      should_end_before_now   -> NaiveDateTime.diff(now, deadline, :minute)
      true -> nil
    end
    # IO.inspect(remoteness, label: "\nREMOTENESS")
    set_rank(task, :remoteness, remoteness)
  end

  defp add_weights(task) do
    [:priority, :urgence]
    |> Enum.reduce(task, fn key, tk ->
      add_weight(tk, key)
    end)
  end

  defp add_weight(task, key) when is_atom(key) do
    pvalue = Map.get(task.task_time, key) || 0
    # IO.inspect(pvalue, label: "Value de #{inspect key}")
    pvalue = pvalue * @weights[key].weight * time_ponderation(task, key)
    set_rank(task, :value, task.rank.value + pvalue)
  end

  defp time_ponderation(task, key) do
    cond do
      is_nil(task.rank.remoteness)  -> 1
      task.rank.remoteness == 0     -> 1
      @weights[key].time_factor     -> @weights[key].time_factor / task.rank.remoteness
      true                          -> 1
    end
  end

  defp set_rank(task, key, value) do
    %{task | rank: %{task.rank | key => value }}
  end
end