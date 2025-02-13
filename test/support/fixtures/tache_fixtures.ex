defmodule Tasker.TacheFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Tasker.Tache` context.
  """

  @doc """
  Generate a task.
  """
  def task_fixture(attrs \\ %{}) do
    {:ok, task} =
      attrs
      |> Enum.into(%{

      })
      |> Tasker.Tache.create_task()

    task
  end

  @doc """
  Generate a task_spec.
  """
  def task_spec_fixture(attrs \\ %{}) do
    {:ok, task_spec} =
      attrs
      |> Enum.into(%{
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
      |> Enum.into(%{
        ended_at: ~N[2025-02-12 16:25:00],
        execution_time: 42,
        expect_duration: 42,
        given_up_at: ~N[2025-02-12 16:25:00],
        priority: 42,
        recurrence: "some recurrence",
        should_end_at: ~N[2025-02-12 16:25:00],
        should_start_at: ~N[2025-02-12 16:25:00],
        started_at: ~N[2025-02-12 16:25:00],
        urgence: 42
      })
      |> Tasker.Tache.create_task_time()

    task_time
  end
end
