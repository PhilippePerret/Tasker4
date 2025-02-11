defmodule Tasker.WorkerEctoTests do
  use Tasker.DataCase
  alias Tasker.{Repo, Worker}

  test "un worker avec des données valides peut s'inscrire" do
    worker = Factory.changeset(:worker, %{})
    assert {:ok, saved_worker} = Repo.insert(worker)
    IO.inspect(saved_worker, label: "Travailleur enregistré")
  end


end