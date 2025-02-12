defmodule Tasker.ProjetTest do
  use Tasker.DataCase

  alias Tasker.Projet

  describe "projects" do
    alias Tasker.Projet.Project

    import Tasker.ProjetFixtures

    @invalid_attrs %{title: nil, details: nil}

    test "list_projects/0 returns all projects" do
      project = project_fixture()
      assert Projet.list_projects() == [project]
    end

    test "get_project!/1 returns the project with given id" do
      project = project_fixture()
      assert Projet.get_project!(project.id) == project
    end

    test "create_project/1 with valid data creates a project" do
      valid_attrs = %{title: "some title", details: "some details"}

      assert {:ok, %Project{} = project} = Projet.create_project(valid_attrs)
      assert project.title == "some title"
      assert project.details == "some details"
    end

    test "create_project/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Projet.create_project(@invalid_attrs)
    end

    test "update_project/2 with valid data updates the project" do
      project = project_fixture()
      update_attrs = %{title: "some updated title", details: "some updated details"}

      assert {:ok, %Project{} = project} = Projet.update_project(project, update_attrs)
      assert project.title == "some updated title"
      assert project.details == "some updated details"
    end

    test "update_project/2 with invalid data returns error changeset" do
      project = project_fixture()
      assert {:error, %Ecto.Changeset{}} = Projet.update_project(project, @invalid_attrs)
      assert project == Projet.get_project!(project.id)
    end

    test "delete_project/1 deletes the project" do
      project = project_fixture()
      assert {:ok, %Project{}} = Projet.delete_project(project)
      assert_raise Ecto.NoResultsError, fn -> Projet.get_project!(project.id) end
    end

    test "change_project/1 returns a project changeset" do
      project = project_fixture()
      assert %Ecto.Changeset{} = Projet.change_project(project)
    end
  end
end
