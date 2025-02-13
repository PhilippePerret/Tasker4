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
end
