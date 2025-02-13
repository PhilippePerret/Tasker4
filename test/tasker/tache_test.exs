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

  describe "task_times" do
    alias Tasker.Tache.TaskTime

    import Tasker.TacheFixtures

    @invalid_attrs %{priority: nil, started_at: nil, should_start_at: nil, should_end_at: nil, ended_at: nil, given_up_at: nil, urgence: nil, recurrence: nil, expect_duration: nil, execution_time: nil}

    test "list_task_times/0 returns all task_times" do
      task_time = task_time_fixture()
      assert Tache.list_task_times() == [task_time]
    end

    test "get_task_time!/1 returns the task_time with given id" do
      task_time = task_time_fixture()
      assert Tache.get_task_time!(task_time.id) == task_time
    end

    test "create_task_time/1 with valid data creates a task_time" do
      valid_attrs = %{priority: 42, started_at: ~N[2025-02-12 16:25:00], should_start_at: ~N[2025-02-12 16:25:00], should_end_at: ~N[2025-02-12 16:25:00], ended_at: ~N[2025-02-12 16:25:00], given_up_at: ~N[2025-02-12 16:25:00], urgence: 42, recurrence: "some recurrence", expect_duration: 42, execution_time: 42}

      assert {:ok, %TaskTime{} = task_time} = Tache.create_task_time(valid_attrs)
      assert task_time.priority == 42
      assert task_time.started_at == ~N[2025-02-12 16:25:00]
      assert task_time.should_start_at == ~N[2025-02-12 16:25:00]
      assert task_time.should_end_at == ~N[2025-02-12 16:25:00]
      assert task_time.ended_at == ~N[2025-02-12 16:25:00]
      assert task_time.given_up_at == ~N[2025-02-12 16:25:00]
      assert task_time.urgence == 42
      assert task_time.recurrence == "some recurrence"
      assert task_time.expect_duration == 42
      assert task_time.execution_time == 42
    end

    test "create_task_time/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Tache.create_task_time(@invalid_attrs)
    end

    test "update_task_time/2 with valid data updates the task_time" do
      task_time = task_time_fixture()
      update_attrs = %{priority: 43, started_at: ~N[2025-02-13 16:25:00], should_start_at: ~N[2025-02-13 16:25:00], should_end_at: ~N[2025-02-13 16:25:00], ended_at: ~N[2025-02-13 16:25:00], given_up_at: ~N[2025-02-13 16:25:00], urgence: 43, recurrence: "some updated recurrence", expect_duration: 43, execution_time: 43}

      assert {:ok, %TaskTime{} = task_time} = Tache.update_task_time(task_time, update_attrs)
      assert task_time.priority == 43
      assert task_time.started_at == ~N[2025-02-13 16:25:00]
      assert task_time.should_start_at == ~N[2025-02-13 16:25:00]
      assert task_time.should_end_at == ~N[2025-02-13 16:25:00]
      assert task_time.ended_at == ~N[2025-02-13 16:25:00]
      assert task_time.given_up_at == ~N[2025-02-13 16:25:00]
      assert task_time.urgence == 43
      assert task_time.recurrence == "some updated recurrence"
      assert task_time.expect_duration == 43
      assert task_time.execution_time == 43
    end

    test "update_task_time/2 with invalid data returns error changeset" do
      task_time = task_time_fixture()
      assert {:error, %Ecto.Changeset{}} = Tache.update_task_time(task_time, @invalid_attrs)
      assert task_time == Tache.get_task_time!(task_time.id)
    end

    test "delete_task_time/1 deletes the task_time" do
      task_time = task_time_fixture()
      assert {:ok, %TaskTime{}} = Tache.delete_task_time(task_time)
      assert_raise Ecto.NoResultsError, fn -> Tache.get_task_time!(task_time.id) end
    end

    test "change_task_time/1 returns a task_time changeset" do
      task_time = task_time_fixture()
      assert %Ecto.Changeset{} = Tache.change_task_time(task_time)
    end
  end
end
