defmodule Tasker.WorkerEctoTests do
  use Tasker.DataCase
  alias Tasker.Repo
  # alias Tasker.Accounts.Worker

  test "un worker avec des données valides peut s'inscrire" do
    worker = Factory.changeset(:worker, %{})
    assert {:ok, _saved_worker} = Repo.insert(worker)
  end


end