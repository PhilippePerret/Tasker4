defmodule Tasker.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Tasker.Accounts` context.
  """

  @doc """
  Generate a worker.
  """
  def worker_fixture(attrs \\ %{}) do
    {:ok, worker} =
      attrs
      |> Enum.into(%{
        email: "some email",
        password: "some password",
        pseudo: "some pseudo"
      })
      |> Tasker.Accounts.create_worker()

    worker
  end
end
