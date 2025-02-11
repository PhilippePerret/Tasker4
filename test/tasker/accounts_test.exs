defmodule Tasker.AccountsTest do
  use Tasker.DataCase

  alias Tasker.Accounts

  describe "workers" do
    alias Tasker.Accounts.Worker

    import Tasker.AccountsFixtures

    @invalid_attrs %{password: nil, pseudo: nil, email: nil}

    test "list_workers/0 returns all workers" do
      worker = worker_fixture()
      assert Accounts.list_workers() == [worker]
    end

    test "get_worker!/1 returns the worker with given id" do
      worker = worker_fixture()
      assert Accounts.get_worker!(worker.id) == worker
    end

    test "create_worker/1 with valid data creates a worker" do
      valid_attrs = %{password: "some password", pseudo: "some pseudo", email: "some email"}

      assert {:ok, %Worker{} = worker} = Accounts.create_worker(valid_attrs)
      # assert worker.password == "some password"
      assert Bcrypt.verify_pass("some password", worker.password)
      assert worker.pseudo == "some pseudo"
      assert worker.email == "some email"
    end

    test "create_worker/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_worker(@invalid_attrs)
    end

    test "update_worker/2 with valid data updates the worker" do
      worker = worker_fixture()
      update_attrs = %{password: "some updated password", pseudo: "some updated pseudo", email: "some updated email"}

      assert {:ok, %Worker{} = worker} = Accounts.update_worker(worker, update_attrs)
      # assert worker.password == "some updated password"
      assert Bcrypt.verify_pass("some updated password", worker.password)
      assert worker.pseudo == "some updated pseudo"
      assert worker.email == "some updated email"
    end

    test "update_worker/2 with invalid data returns error changeset" do
      worker = worker_fixture()
      assert {:error, %Ecto.Changeset{}} = Accounts.update_worker(worker, @invalid_attrs)
      assert worker == Accounts.get_worker!(worker.id)
    end

    test "delete_worker/1 deletes the worker" do
      worker = worker_fixture()
      assert {:ok, %Worker{}} = Accounts.delete_worker(worker)
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_worker!(worker.id) end
    end

    test "change_worker/1 returns a worker changeset" do
      worker = worker_fixture()
      assert %Ecto.Changeset{} = Accounts.change_worker(worker)
    end
  end
end
