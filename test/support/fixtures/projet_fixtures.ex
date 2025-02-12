defmodule Tasker.ProjetFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Tasker.Projet` context.
  """

  @doc """
  Generate a project.
  """
  def project_fixture(attrs \\ %{}) do
    {:ok, project} =
      attrs
      |> Enum.into(%{
        details: "some details",
        title: "some title"
      })
      |> Tasker.Projet.create_project()

    project
  end
end
