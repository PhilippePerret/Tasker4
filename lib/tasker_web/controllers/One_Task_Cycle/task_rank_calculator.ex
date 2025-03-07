defmodule Tasker.TaskRankCalculator do
  @moduledoc """


  PRÉFÉRENCES
  -----------
  Les préférences du worker agissent sur le choix et l'ordre des
  tâches qui seront remontées. 
  Ces préférences sont ajoutées ci-dessous dans l'argument 'options'
  donné en seconde paramètre à la fonction sort/2 du module.
  Ces préférences 
    options = [
      {:prefs, [
        {:sort_by_task_duration, :long|:short|nil},
        {:default_task_duration, <nombre de minutes|30>},
        {:prioritize_same_nature, true|false|nil}
      ]}
    ]
  """

  alias Tasker.Tache
  alias Tasker.Tache.{Task, TaskRank}

  @now NaiveDateTime.utc_now()
  @hour 60
  @day  @hour * 24
  @week @day * 7

  @weights %{
    priority:           %{weight:   100_000,    time_factor: 7.5},
    urgence:            %{weight:   50_000,     time_factor: 7.5},
    remoteness:         %{weight:     100,      time_factor: 5},
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
    almost_finished:    %{weight:     250,      time_factor: nil},
    # Une tâche avec des tâches dépendantes d'elle prend des points
    with_dependencies:  %{weight:     200,      time_factor: nil}, 
    # En fonction du temps de travail restant dans la journée et du
    # temps de travail sur la tâche
    work_time_left:     %{weight:    5_000,      time_factor: nil},
    # En fonction de la difficulté (si choisi par le worker)
    by_task_difficulty: %{weight:     1000,       time_factor: nil},
    # En fonction de la durée de la tâche, proportionnellement aux
    # autres
    per_duration:       %{weight:     250,      time_factor: nil}
  }
  @weight_keys Map.keys(@weights)

  # Pour les tests
  def weights, do: @weights

  @doc """
  @main
  Fonction principale qui reçoit une liste de tache (Task) et les
  classe par task_rank avant de les envoyer au client pour usage.
  @main
  @api

  ## Examples

    iex> RCalc.sort([])
    []

  @param {List of %Task{}} task_list Liste des structures Task.
  """
  def sort(task_list, options \\ []) when is_list(task_list) do
    options = add_current_work_time_left(options)
    task_list
    |> Enum.map(&calc_task_rank(&1, options))
    |> add_weight_per_duration(options)
    |> Enum.sort_by(&(&1.rank.value), :desc)
    |> range_per_natures(options)
    |> Enum.with_index()
    |> Enum.map(fn {task, index} -> set_rank(task, :index, index) end)
  end

  def add_current_work_time_left(options) do
    if (options == []) or is_nil(options[:prefs][:morning_end_time]) do
      options
    else
      morning_end   = horloge_to_minutes(options[:prefs][:morning_end_time])
      day_end       = horloge_to_minutes(options[:prefs][:work_end_time])
      cur_time = horloge_to_minutes("#{@now.hour}:#{@now.minute}")

      time =
      cond do
      cur_time < morning_end  -> morning_end - cur_time
      cur_time < day_end      -> day_end - cur_time
      true -> 0 # on travaille hors horaires
      end # |> IO.inspect(label: "time")
      Keyword.put(options, :current_work_time_left, time)
    end
  end
  defp horloge_to_minutes(horloge) do
    [hour, min] = String.split(horloge, ":")
    String.to_integer(hour) * 60 + String.to_integer(min)
  end

  @doc """
  Fonction qui calcule le task_rank d'une tâche et le retourne.

  @param {Task} task    Une tâche à exécuter
  @return {Task} La tâche avec son rank calculé
  """
  def calc_task_rank(%Task{} = task, options) do
    %{ task | rank: %TaskRank{} }
    |> calc_remoteness()
    |> add_weights(options)
  end

  @doc """
  Ajoute de la durée à chaque tâche en fonction de sa durée et des
  choix du travailleur. Si le worker privilégie les tâches courtes
  plus les tâches sont courtes dans les tâches relevées et plus elles
  reçoivent de points. Et inversement si le workder a choisi de pri-
  vilégier les tâches longues.
  """
  def add_weight_per_duration(tasks, options) do
    if is_nil(options[:prefs][:sort_by_task_duration]) do
      tasks
    else
      tasks
      |> Enum.map(fn task -> 
        %{task: task, duration: task.task_time.expect_duration || options[:prefs][:default_task_duration] || 30 }
      end)
      |> Enum.sort_by(&(&1.duration))
      # |> IO.inspect(label: "TRIÉES PAR DURÉE")
      |> (fn liste -> 
        options[:prefs][:sort_by_task_duration] == :long && liste || Enum.reverse(liste)
      end).()
      |> Enum.with_index()
      |> Enum.map(fn {map, index} -> 
        poids = index * @weights[:per_duration].weight
        set_rank(map.task, :value, map.task.rank.value + poids)
        # |> IO.inspect(label: "TACHE AVEC POIDS DUREE")
      end)
    end
  end

  @doc """
  Cette fonction range la liste de tâches +list+ en fonction des
  choix par rapport aux natures défini par : 
    options.prefs.prioritize_same_nature
  qui peut avoir les valeurs :
    true    Privilégier les tâches de même nature
            Concrètement, ça signifie que si deux tâches de même
            nature sont séparées par une tâche, on les rapproche.
    false   Éviter d'enchainer les tâches de même nature
            Concrètement, ça signifie que si deux tâches de même
            nature se suivent, on éloigne la deuxième
    nil     Indifférent

  @return La liste des tâches classée (ou gardée telle quelle)
  """
  def range_per_natures(list, options) do
    case options[:prefs][:prioritize_same_nature] do
    true  -> rapproche_same_natures_in(list) # |> debug_liste_taches()
    false -> eloigne_same_natures_in(list)
    nil   -> list
    end
  end
  defp rapproche_same_natures_in(list) do
    list = list
    |> Enum.map(fn tk ->
      %{tk | natures: Enum.map(tk.natures, fn nature -> nature.id end)}
    end)

    last_index = Enum.count(list) - 3
    (0..last_index)
    |> Enum.reduce(list, fn index, nlist ->
      task   = Enum.at(nlist, index)
      # IO.inspect(task, label: "TASK")
      next_1 = Enum.at(nlist, index + 1)
      next_2 = Enum.at(nlist, index + 2)
      if !share_natures?(task, next_1) and share_natures?(task, next_2) do
        # <=  Si la tâche suivante ne partage aucune nature mais que 
        #     la tache + 2 en partage 
        # =>  On remonte la tâche + 2
        Enum.slide(nlist, index + 2, index + 1)
        # |> debug_liste_taches()
      else
        nlist
      end
    end)
  end

  # Traitement de l'éloignement des tâches de même(s) nature(s)
  # Principe :
  #   Si une tâche suivante partage les mêmes natures que la tâche
  #   précédente, on doit l'éloigner.
  # MAIS
  #   Pour ne pas déséquilibrer les ranks, on ne le fait qu'une fois
  #   et seulement si le déplacement est intéressant.
  defp eloigne_same_natures_in(list) do
    last_index = Enum.count(list) - 2 # on ne peut pas faire descendre la dernière
    (1..last_index)
    |> Enum.reduce(list, fn index, nlist ->
      pretk = Enum.at(nlist, index - 1)
      curtk = Enum.at(nlist, index)
      nextk = Enum.at(nlist, index + 1)
      if share_natures?(pretk, curtk) && !share_natures?(curtk, nextk) do
        Enum.slide(nlist, index, index + 1)
        # |> debug_liste_taches()
      else
        nlist
      end
    end)
  end


  defp debug_liste_taches(liste) do
    liste |> Enum.map(fn tk ->
      natures = 
      case Enum.at(tk.natures, 0) do
      nature when is_binary(nature) -> Enum.join(tk.natures, ", ")
      _ -> Enum.map(tk.natures, fn nat -> nat.id end) |> Enum.join(", ")
      end
      IO.puts "- T. #{tk.id} rank:#{tk.rank.value} -- #{natures}"
    end)
    liste
  end

  # On retourne true dès qu'une nature commune a été trouvée
  defp share_natures?(tk1, tk2) do
    natures1 = tk1.natures || []
    natures2 = tk2.natures || []
    Enum.any?(MapSet.intersection(MapSet.new(natures1), MapSet.new(natures2)))
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

  # Liste des clés qui ont besoin des options (préférences du worker)
  @properties_with_options [:work_time_left, :by_task_difficulty]


  defp add_weights(task, options) do
    @weight_keys
    |> Enum.reduce(task, fn key, tk ->
      cond do
      Enum.member?(@properties_with_options, key) -> 
        add_weight(tk, key, options)
      true -> 
        add_weight(tk, key) 
      end
    end)
  end

  @doc """
  FonctionS ajoutant le poids à la tâche suivant la propriété définie

  @param {%Task} task La tâche concernée
  @param {Atom} property  La propriété de poids

  @return {%Task} La tâche concernée, avec dans son :rank la valeur
  de poids ajoutée.
  """

  # Difficulté de tâche
  def add_weight(task, :by_task_difficulty, options) do
    if (options == []) or is_nil(options[:prefs][:sort_by_task_difficulty]) do
      task
    else
      # <= Il faut classer par difficulté de la tâche
      coef =
      case options[:prefs][:sort_by_task_difficulty] do
      :hard -> 1
      :easy -> -1
      _ -> raise "Option mal défini : :sort_by_task_duration (:hard, :easy or nil)"
      end
      poids = ( task.task_spec.difficulty || 3 ) * @weights[:by_task_difficulty].weight
      set_rank(task, :value, task.rank.value + (poids * coef))
    end
  end
  
  # Temps de travail restant

  def add_weight(task, :work_time_left, options) do
    if options[:current_work_time_left] > 30 do
      task
    else
      # <= Un temps de travail inférieur à la demi-heure
      # => On privilégie les tâches à temps de travail restant courts
      ttime = task.task_time
      cond do
      is_nil(ttime.expect_duration) -> 
        task
      true ->
        work_left_tache = (ttime.expect_duration) - (ttime.execution_time || 0)
        if work_left_tache < 30 do
          set_rank(task, :value, task.rank.value + @weights[:work_time_left].weight)
        else task end
      end
    end
  end

  # Éloignement de l'échéance
  def add_weight(task, :remoteness) do
    headline = task.task_time.should_start_at
    if task.rank.remoteness > 0 and !is_nil(headline) and NaiveDateTime.compare(@now, headline) == :lt do
      poids = 2 * @week / task.rank.remoteness * @weights[:remoteness].weight
      set_rank(task, :value, task.rank.value + poids)
    else task end
  end

  # Tâche avec dépendances
  # Note : task.dependencies ne contient que la liste des dépendances
  def add_weight(task, :with_dependencies) do
    nombre_dependances = Enum.count(task.dependencies || [])
    if nombre_dependances > 0 do
      poids = @weights[:with_dependencies].weight * nombre_dependances
      set_rank(task, :value, task.rank.value + poids)
    else task end
  end

  # Échéance expirée
  def add_weight(task, :headline_expired = prop) do
    ttime = task.task_time
    if !is_nil(ttime.should_start_at) and is_nil(ttime.started_at) do
      if is_nil(task.rank.remoteness) do
        raise "remoteness ne devrait pas pouvoir être nil avec should_end_at à #{task.task_time.should_end_at}"
      end
      if NaiveDateTime.compare(ttime.should_start_at, @now) == :lt do
        weight = task.rank.remoteness * @weights[prop].weight
        set_rank(task, :value, task.rank.value + weight)
      else task end
    else task end
  end
  def add_weight(task, :deadline_expired = prop) do
    ttime = task.task_time
    if is_nil(ttime.should_start_at) and !is_nil(ttime.should_end_at) and is_nil(ttime.started_at) do
      if is_nil(task.rank.remoteness) do
        raise "remoteness ne devrait pas pouvoir être nil avec should_end_at à #{ttime.should_end_at}"
      end
      if NaiveDateTime.compare(ttime.should_end_at, @now) == :lt do
        weight = task.rank.remoteness * @weights[prop].weight
        set_rank(task, :value, task.rank.value + weight)
      else task end
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
  # poids est élevé.
  # Attention : pour une tâche concernée, le remoteness est à 0, 
  # puisque le remoteness ne compte que l'éloignement d'une tâche NON
  # DÉMARÉE
  def add_weight(task, :started_long_ago = key) do
    ttime = task.task_time
    if is_nil(ttime.should_start_at) and is_nil(ttime.should_end_at) and (!is_nil(ttime.started_at)) do
      start_remoteness = NaiveDateTime.diff(@now, ttime.started_at, :minute)
      time_emphasis = start_remoteness * @weights[key].time_factor
      poids = @weights[key].weight * time_emphasis
      # IO.puts """
      # CALCUL POIDS = 
      # @weights[key].weight * start_remoteness * @weights[key].time_factor
      # => #{@weights[key].weight} * #{start_remoteness} * #{@weights[key].time_factor}
      # => #{poids}
      # """
      set_rank(task, :value, task.rank.value + poids)
    else task end
  end

  def add_weight(task, key) when is_atom(key) do
    poids = Map.get(task.task_time, key) || 0
    poids = poids * @weights[key].weight * time_ponderation(task, key)
    set_rank(task, :value, task.rank.value + poids)
  end

  defp time_ponderation(task, key) do
    # IO.puts "-> time_ponderation avec key=#{inspect key}"
    # IO.puts "-> time_ponderation(key=#{inspect key}) / factor: #{@weights[key].time_factor} / remoteness: #{inspect task.rank.remoteness}"
    cond do
      is_nil(task.rank.remoteness)  -> 1
      is_nil(@weights[key][:time_factor]) -> 1
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