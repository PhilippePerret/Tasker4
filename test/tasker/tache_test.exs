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
      valid_attrs = %{title: "Tâche du #{NaiveDateTime.utc_now()}"}

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
      {:ok, task} = Tache.create_task(%{title: "Une tâche à associer à sa fiche spec"})

      valid_attrs = %{details: "some details", task_id: task.id}

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

    @invalid_attrs %{}

    test "list_task_times/0 returns all task_times" do
      task_time = task_time_fixture()
      assert Tache.list_task_times() == [task_time]
    end

    test "get_task_time!/1 returns the task_time with given id" do
      task_time = task_time_fixture()
      assert Tache.get_task_time!(task_time.id) == task_time
    end

    test "create_task_time/1 with valid data creates a task_time" do
      valid_attrs = task_time_valid_attrs()
      assert {:ok, %TaskTime{} = task_time} = Tache.create_task_time(valid_attrs)
      assert task_time.priority == valid_attrs.priority
      assert are_same_time(task_time.started_at, valid_attrs.started_at)
      assert are_same_time(task_time.should_start_at, valid_attrs.should_start_at)
      assert are_same_time(task_time.should_end_at, valid_attrs.should_end_at)
      assert are_same_time(task_time.ended_at, valid_attrs.ended_at)
      assert are_same_time(task_time.given_up_at, valid_attrs.given_up_at)
      assert task_time.urgence == valid_attrs.urgence
      assert task_time.recurrence == valid_attrs.recurrence
      assert task_time.expect_duration == valid_attrs.expect_duration
      assert task_time.execution_time == valid_attrs.execution_time
    end

    test "create_task_time/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Tache.create_task_time(@invalid_attrs)
    end

    test "update_task_time/2 with valid data updates the task_time" do
      task_time = task_time_fixture()
      update_attrs = task_time_valid_attrs()

      assert {:ok, %TaskTime{} = task_time} = Tache.update_task_time(task_time, update_attrs)
      assert task_time.priority == update_attrs.priority
      assert are_same_time(task_time.started_at, update_attrs.started_at)
      assert are_same_time(task_time.should_start_at, update_attrs.should_start_at)
      assert are_same_time(task_time.should_end_at, update_attrs.should_end_at)
      assert are_same_time(task_time.ended_at, update_attrs.ended_at)
      assert are_same_time(task_time.given_up_at, update_attrs.given_up_at)
      assert task_time.urgence == update_attrs.urgence
      assert task_time.recurrence == update_attrs.recurrence
      assert task_time.expect_duration == update_attrs.expect_duration
      assert task_time.execution_time == update_attrs.execution_time
    end

    test "update_task_time/2 with invalid data returns error changeset" do
      # Note à propos des possibilités étranges
      # 
      #   On peut avoir une date de fin (ended_at) sans date de début
      #   (si on en a besoin, le programme "invente" la date de début)
      task_time = task_time_fixture()
      now = NaiveDateTime.utc_now()
      started_at = random_time(:before, 1_000_000)
      # Une date de fin ne peut être avant la date de début
      bad_end_from_start = %{started_at: started_at, ended_at: random_time(:before, started_at)}
      # Une date de désir de fin ne peut être avant une date de désir de début
      should_start_at = random_time()
      bad_should_end_from_should_start = %{should_start_at: should_start_at, should_end_at: random_time(:before, should_start_at)}
      # Une date d'abandon ne peut co-exister avec une date de fin
      bad_end_and_given_up = %{ended_at: random_time(:between, started_at, now), given_up_at: random_time(:between, started_at, now) }

      # On passe ne revue chaque impossibilité
      [
        bad_end_from_start,
        bad_should_end_from_should_start,
        bad_end_and_given_up
      ] |> Enum.each(fn bad_attrs -> 
        # IO.inspect(bad_attrs, label: "\nMAUVAIS ATTRIBUTS")
        # La tâche ne peut pas être actualisée
        assert {:error, %Ecto.Changeset{}} = Tache.update_task_time(task_time, bad_attrs)
        # La tâche n'a pas changé
        assert task_time == Tache.get_task_time!(task_time.id)
      end)
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
