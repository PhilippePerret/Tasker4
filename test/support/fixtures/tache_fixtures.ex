defmodule Tasker.TacheFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Tasker.Tache` context.
  """

  use Tasker.DataCase

  alias Tasker.Tache

  alias Tasker.Accounts.Worker
  alias Tasker.AccountsFixtures, as: WF

  # Les durées en minutes
  @hour   60
  @day    @hour * 24
  @week   @day * 7
  # @month  @week * 4


  defp set_spec_time(task_data, prop, spec) do
    if !spec do
      task_data
    else
      thetime = 
      case spec do
        true          -> random_time()
        :future       -> random_time(:after)
        :now          -> now()
        :past         -> random_time(:before)
        :near_past    -> random_time(:before, NaiveDateTime.add(now(), - :rand.uniform(@day * 2), :minute), @day)
        :near_future  -> 
          random_time(:after, NaiveDateTime.add(now(), :rand.uniform(@day * 2), :minute), @day)
          # |> IO.inspect(label: "\nFutur proche (pour #{inspect prop})")
          :far_past     -> random_time(:before, NaiveDateTime.add(now(), - @week * 2, :minute), @day)
          :far_future   -> 
            random_time(:after, NaiveDateTime.add(now(), @week * 2, :minute), @day)
            # |> IO.inspect(label: "\nFutur lointain (> 2 semaines) (pour #{inspect prop})")
        %NaiveDateTime{} -> spec
        _ -> spec
      end        
      %{task_data | task_time: %{task_data.task_time | prop => thetime}}
    end
  end

  @doc """
  Fonction beaucoup plus "solide" que task_fixture ci-dessous qui
  permet de créer une tâche complète, avec ses fichiers associées
  dont task_spec, task_time et ?

  Les attrs possibles sont les suivants (tout paramètre absent est
  considéré comme faux) :

    :project      yes|no      Peut être fourni
    :headline     yes|no      future|now|past
    :started      yes|no      far|now|near
    :deadline     yes|no      future|now|past
    :ended (IMPOSSIBLE <= archivée ailleurs)
    :deps_before  yes|no      Dépendante d'une tâche avant (à faire)
    :deps_after   yes|no      Des tâches futures dépendent d'elle
    :worker       yes|no      (attributation de la tâche à un worker)
    :natures      yes|no      Liste des natures
    :rank         true    Ajout de la structure TaskRank
                  %TaskRank{}   On met ce task_rank
    :duree        :expect_duration
    :exec_duree   :execution_time

  """
  def create_task(attrs \\ %{}) do
    dtask = %{
      task: %{
        title: attrs[:title] || random_title(),
        project_id: attrs[:project_id],
      },
      task_spec: %{
        details: attrs[:details]
      },
      task_time: %{
        should_start_at:  nil,
        should_end_at:    nil,
        started_at:       nil,
        priority:         attrs[:priority],
        urgence:          attrs[:urgence],
        expect_duration:  attrs[:duree]||attrs[:expect_duration],
        execution_time:   attrs[:exec_duree]||attrs[:execution_time]
      },
    }

    # - HEADLINE -
    dtask = set_spec_time(dtask, :should_start_at, attrs[:headline])
    # - DEADLINE -
    attrs = 
      if attrs[:deadline] === true && attrs[:headline] do
        %{attrs | deadline: random_time(:after, dtask.task_time.should_start_at)}
      else attrs end
    dtask = set_spec_time(dtask, :should_end_at, attrs[:deadline])


    {:ok, task} = Tache.create_task(dtask.task)
    task = Tache.get_task!(task.id)
    Tache.update_task_spec(task.task_spec, dtask.task_spec)
    Tache.update_task_time(task.task_time, dtask.task_time)
    # Il faut la relever pour avoir les bonnes valeurs
    task = Tache.get_task!(task.id)

    # - STARTED -
    attrs = 
      case attrs[:started] do
        true -> %{attrs | started: random_time(:before)}
        NaiveDateTime -> %{attrs | started: attrs[:started]}
        _ -> attrs
      end
    task = set_spec_time(task, :started_at, attrs[:started])

    # - Durée estimée -
    task = if attrs[:duree] do
      set_spec_time(task, :expect_duration, attrs[:duree])
    else task end

    # - Temps d'exécution -
    task = if attrs[:exec_duree] do
      set_spec_time(task, :execution_time, attrs[:exec_duree])
    else task end

    # - DÉPENDANTE -
    case attrs[:deps_before] do
      nil     -> nil
      false   -> nil
      true    ->
        # Sans autre forme d'information, on fait une tâche
        # précédente qui est commencée depuis peu
        # Sinon, définir la tâche en appelant cette fonction
        headline  = random_time(:before, @day)
        started   = random_time(:between, headline, now())
        task_before = create_task(%{
          headline: headline,
          started:  started,
          should_end_at: random_time(:after, started)
        })
        Tache.create_dependency(task_before, task)
      %Task{} ->
        Tache.create_dependency(attrs[:deps_before], task)
    end

    # - DÉPENDANCE -
    task =
    case attrs[:deps_after] do
    nil   -> task
    false -> task
    nombre when is_integer(nombre) ->
      (1..nombre) |> Enum.each(fn _index -> 
        Tache.create_dependency(task, create_task())
      end)
      Tache.get_task!(task.id)
    true  -> 
      # Sans autre forme d'information, on fait une tâche
      # suivantte.
      Tache.create_dependency(task, create_task())
    %Task{} ->
      # Une tâche après est définie
      Tache.create_dependency(task, attrs[:deps_after])
    end

    # - NATURES -
    task =
    case attrs[:natures] do
      nil   -> task
      false -> task
      nature when is_binary(nature) ->
        Tache.inject_natures(task, nature)
      natures when is_list(natures) ->
        Tache.inject_natures(task, natures)
    end

    # - ASSIGNATION -
    task =
    case attrs[:worker] do
      nil   -> task
      false -> task
      true  -> 
        Tache.assign_to(task, WF.create_worker())
      %Worker{} -> 
        Tache.assign_to(task, attrs[:worker])
    end

    task =
    case attrs[:rank] do
      nil -> task
      true -> 
        %{task | rank: %Tasker.Tache.TaskRank{} }
      %Tasker.Tache.TaskRank{} -> 
        %{task | rank: attrs[:rank] }
    end

    # On retourne la tâche créée
    task

  end

  @doc """
  Generate a task.
  """
  def task_fixture(attrs \\ %{}) do
    {:ok, task} =
      attrs
      |> Enum.into(%{
        title: "Une tâche pour #{NaiveDateTime.utc_now()}"
      })
      |> Tasker.Tache.create_task()

    task
  end

  @doc """
  Generate a task_spec.
  """
  def task_spec_fixture(attrs \\ %{}) do
    task = task_fixture()
    {:ok, task_spec} =
      attrs
      |> Enum.into(%{
        task_id: task.id,
        details: "some details"
      })
      |> Tasker.Tache.create_task_spec()

    task_spec
  end

  @doc """
  Generate a task_time.
  """
  def task_time_fixture(attrs \\ %{}) do
    {:ok, task_time} =
      attrs
      |> Enum.into(task_time_valid_attrs(attrs))
      |> Tasker.Tache.create_task_time()

    task_time
  end

  @doc """
  Retourne des attributs VALIDE pour task_time valides.
  """
  def task_time_valid_attrs(attrs \\ %{}) do
    # La table des arguments
    a = %{
      task_id:          attrs[:task_id] || task_fixture().id,
      should_start_at:  nil,
      should_end_at:    nil,
      started_at:       nil,
      ended_at:         nil,
      execution_time:   nil,
      expect_duration:  nil,
      priority:         Enum.random(0..5),
      urgence:          Enum.random(0..5),
      recurrence:       "*/10 * * * *",
      given_up_at:      nil
    }
    now = NaiveDateTime.utc_now()

    is_done = t_or_f()

    a = 
    if is_done do
      started_at = random_time(:before)
      ended_at   = random_time(:between, started_at, now)
      real_execution_time = NaiveDateTime.diff(started_at, ended_at, :minute)
      execution_time = Enum.random((real_execution_time-100..real_execution_time))
      Map.merge(a, %{
        started_at: started_at,
        ended_at: ended_at,
        execution_time: execution_time
      })
    else a end

    # given_up_at
    a = if t_or_f() do
      # Il faut une date d'abandon
      started_at = a.started_at && a.started_at || random_time(:before)
      given_up_at = random_time(:after, started_at)
      Map.merge(a, %{
        started_at:   started_at,
        ended_at:     nil,
        given_up_at:  given_up_at
      })
    else a end

    a = %{a | expect_duration: t_or_f() && Enum.random(120..15_000) || nil}
    a = %{a | should_start_at: (t_or_f() && random_time() || nil) }
    a = %{a | should_end_at: (t_or_f() && (a.should_start_at && random_time(:after, a.should_start_at) || random_time()) || nil) }

    # expect_duration
    a = 
      if t_or_f() do
        duration =
          if a.should_start_at && a.should_end_at do
            NaiveDateTime.diff(a.should_start_at, a.should_end_at, :minute)
          else
            Enum.random(15..1_000_000)
          end
        %{a | expect_duration: duration}
      else a end

    # Pour le retour
    Map.merge(a, attrs)
  end

  def t_or_f, do: Enum.random([true, true, true, false])
  
  # ---- MÉTHODES PRATIQUES POUR LES TEMPS ----

  def are_same_time(date1, date2) do
    if is_nil(date1) do
      date1 == date2
    else
      # Si ce sont vraiment des dates
      assert NaiveDateTime.truncate(date1, :second) == NaiveDateTime.truncate(date2, :second)
    end
  end

  @doc """
  Retourne un titre de tâche aléatoire
  """
  def random_title do
    "#{random_action()} #{random_objet()} n°#{:rand.uniform(1000)} du #{random_time(:before)}"
  end
  @task_actions ["Concevoir", "Rechercher","Lire","Consulter", "Corriger", "Revoir", "Discuter"]
  # @task_actions_count Enum.count(@task_actions) - 1
  defp random_action do
    Enum.random(@task_actions)
  end
  @task_objets ["le document", "la recette", "le rapport", "le compte-rendu", "le manuscrit", "le vade mecum", "la affaire"]
  # @task_objets_count Enum.count(@task_objets) - 1
  defp random_objet do
    Enum.random(@task_objets)
  end

  @doc """
  @return %NaiveDateTime{} La date de maintenant
  """
  def now do
    NaiveDateTime.utc_now()
  end

  @doc """
  Retourne une date aléatoire par rapport à maintenant

  random_time/0   retourne une date autour de maintenant, avant ou 
                  après, dans un intervalle de 1 000 000 de minutes

  random_time/1   retourne une date soit avant soit après dans un
                  intervalle aléatoire de minutes.
                  :after ou :before en premier argument.

  random_time/2   ( :after|:before, Integer.t() )
                  retourne une date soit avant soit après dans un
                  intervalle fixé de minutes.
                  
  random_time/2   (:after|:before, NaiveDateTime.t())
                  Retourne une date avant ou après la date de réfé-
                  rence dans un intervalle de 1 000 000 de minutes
  
  random_time/3   (:after|:before, NaiveDateTime.t(), Integer.t())
                  Retourne une date avant ou après la date de réfé-
                  rence dans un intervalle de minutes fixés (par le
                  troisième argument)

  random_time/3   (:between, NaiveDateTime.t(), NaiveDateTime.t())
                  Retourne une date aléatoire entre les deux dates
                  fournie.

  """
  # Sans rien du tout
  def random_time() do
    random_time(1_000_000)
  end
  # Juste avec le laps, c'est une date autour de maintenant
  def random_time(max_laps) when is_integer(max_laps) do
    random_time(NaiveDateTime.utc_now(), max_laps)
  end
  # Positionnée avant ou après sans laps précisé
  # @param {Atom} position  Soit :after soit :before
  def random_time(position) when is_atom(position) do
    random_time(position, 1_000_000)
  end
  def random_time(ref_time) when not is_atom(ref_time) and not is_integer(ref_time) do
    random_time(ref_time, 1_000_000)
  end
  # Positionnée avant ou après
  def random_time(position, max_laps) when is_atom(position) and is_integer(max_laps) do
    random_time(position, NaiveDateTime.utc_now(), max_laps)
  end
  def random_time(position, ref_time) when is_atom(position) and not is_integer(ref_time) do
    random_time(position, ref_time, 1_000_000)
  end
  def random_time(ref_time, max_laps) when not is_atom(ref_time) and is_integer(max_laps) do
    ref_time
    |> NaiveDateTime.add(Enum.random((-max_laps..max_laps)), :minute)
  end
  # AVANT une date de référence fournie, dans un intervalle donné
  # en minute
  def random_time(:before, ref_time, max_laps) do
    ref_time
    |> NaiveDateTime.add(Enum.random((-max_laps..-1)), :minute)
  end
  # APRÈS une date de référence fournie, dans un intervalle donné
  # en minute
  def random_time(:after, ref_time, max_laps) do
    ref_time
    |> NaiveDateTime.add(Enum.random((1..max_laps)), :minute)
  end
  def random_time(:between, time_before, time_after) do
    diff = NaiveDateTime.diff(time_after, time_before, :minute)
    NaiveDateTime.add(time_before, Enum.random((0..diff)), :minute)
  end


end
