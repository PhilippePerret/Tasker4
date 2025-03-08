defmodule Tasker.ProjetFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Tasker.Projet` context.
  """

  import Random.RandMethods

  @doc """
  Crée +nombre+ projets et les retourne.
  
  """
  def create_projects(nombre, attrs \\ %{}) do
    (1..nombre)
    |> Enum.map(fn _index -> project_fixture(attrs) end)
  end

  @doc """
  Generate a project.
  """
  def project_fixture(attrs \\ %{}) do
    {:ok, project} =
      attrs
      |> Enum.into(%{
        title: attrs[:title] || random_title(),
        details: attrs[:details] || random_details()
      })
      |> Tasker.Projet.create_project()

    project
  end

  defp random_title do
    d = NaiveDateTime.add(NaiveDateTime.utc_now(), - Enum.random(0..100000), :hour)
    "Le projet #{random_adjectif()} du #{d.day} #{d.month} #{d.year}"
  end

  defp random_details(longueur \\ 200) do
    random_text(longueur)
  end


end
