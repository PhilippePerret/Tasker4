defmodule Tasker.TacheTest do
  use Tasker.DataCase

  alias Tasker.Tache

  describe "tasks" do
    alias Tasker.Tache.Task

    import Tasker.TacheFixtures

    @invalid_attrs %{}

    test "list_tasks/0 returns all tasks" do
      task = task_fixture()
      assert Tache.list_tasks() == [task]
    end

    test "get_task!/1 returns the task with given id" do
      task = task_fixture()
      assert Tache.get_task!(task.id) == task
    end

    test "create_task/1 with valid data creates a task" do
      valid_attrs = %{}

      assert {:ok, %Task{} = _task} = Tache.create_task(valid_attrs)
    end
    test "update_task/2 with valid data updates the task" do
      task = task_fixture()
      update_attrs = %{}

      assert {:ok, %Task{} = _task} = Tache.update_task(task, update_attrs)
    end

    test "delete_task/1 deletes the task" do
      task = task_fixture()
      assert {:ok, %Task{}} = Tache.delete_task(task)
      assert_raise Ecto.NoResultsError, fn -> Tache.get_task!(task.id) end
    end

    test "change_task/1 returns a task changeset" do
      task = task_fixture()
      assert %Ecto.Changeset{} = Tache.change_task(task)
    end
  end

  describe "task_specs" do
    alias Tasker.Tache.TaskSpec

    import Tasker.TacheFixtures

    @invalid_attrs %{details: nil}

    test "list_task_specs/0 returns all task_specs" do
      task_spec = task_spec_fixture()
      assert Tache.list_task_specs() == [task_spec]
    end

    test "get_task_spec!/1 returns the task_spec with given id" do
      task_spec = task_spec_fixture()
      assert Tache.get_task_spec!(task_spec.id) == task_spec
    end

    test "create_task_spec/1 with valid data creates a task_spec" do
      valid_attrs = %{details: "some details"}

      assert {:ok, %TaskSpec{} = task_spec} = Tache.create_task_spec(valid_attrs)
      assert task_spec.details == "some details"
    end

    test "create_task_spec/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Tache.create_task_spec(@invalid_attrs)
    end

    test "update_task_spec/2 with valid data updates the task_spec" do
      task_spec = task_spec_fixture()
      update_attrs = %{details: "some updated details"}

      assert {:ok, %TaskSpec{} = task_spec} = Tache.update_task_spec(task_spec, update_attrs)
      assert task_spec.details == "some updated details"
    end

    test "update_task_spec/2 with invalid data returns error changeset" do
      task_spec = task_spec_fixture()
      assert {:error, %Ecto.Changeset{}} = Tache.update_task_spec(task_spec, @invalid_attrs)
      assert task_spec == Tache.get_task_spec!(task_spec.id)
    end

    test "delete_task_spec/1 deletes the task_spec" do
      task_spec = task_spec_fixture()
      assert {:ok, %TaskSpec{}} = Tache.delete_task_spec(task_spec)
      assert_raise Ecto.NoResultsError, fn -> Tache.get_task_spec!(task_spec.id) end
    end

    test "change_task_spec/1 returns a task_spec changeset" do
      task_spec = task_spec_fixture()
      assert %Ecto.Changeset{} = Tache.change_task_spec(task_spec)
    end
  end
end
