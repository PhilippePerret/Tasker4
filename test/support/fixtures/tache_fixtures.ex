defmodule Tasker.TacheFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Tasker.Tache` context.
  """

  use Tasker.DataCase

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
    # La table des argument
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
