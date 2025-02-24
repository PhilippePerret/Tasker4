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

    iex> RankCalc.calc_task_rank(task = F.create_task())
    task

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

  ## EXAMPLES

    iex> RankCalc.calc_remoteness(task = F.create_task(headline: :near_future, rank: true)).rank.remoteness
    > 0

    iex> RankCalc.calc_remoteness(task = F.create_task(deadline: :near_past, rank: true)).rank.remoteness
    > 0

    iex> RankCalc.calc_remoteness(task = F.create_task(started_at: :near_past, rank: true)).rank.remoteness
    0


  On 
  """
  def calc_remoteness(task) do
    is_started  = !is_nil(task.task_time.started_at)
    headline    = task.task_time.should_start_at
    deadline    = task.task_time.should_end_at
    now = NaiveDateTime.utc_now()

    remoteness =
    cond do
      is_started -> 0
      headline && headline > now -> NaiveDateTime.diff(now, headline, :minute)
      headline && headline < now -> NaiveDateTime.diff(headline, now, :minute) / 4 # on rapproche beaucoup, quand la headline est dépassée
      deadline && deadline < now -> NaiveDateTime.diff(deadline, now, :minute)
      deadline && deadline > now -> NaiveDateTime.diff(now, deadline, :minute) / 2 # on rapproche, quand c'est la deadline
      true -> nil
    end
    set_rank(task, :remoteness, remoteness)
  end

  defp add_weights(task) do
    [:priority, :urgence]
    |> Enum.reduce(task, fn key, tk ->
      add_weight(tk, key)
    end)
  end

  defp add_weight(task, key) when is_atom(key) do
    pvalue = Map.get(task.task_time, key, 0)
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