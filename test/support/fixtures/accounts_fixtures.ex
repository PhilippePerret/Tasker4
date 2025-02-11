defmodule Tasker.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Tasker.Accounts` context.
  """


  def unique_worker_email, do: "worker#{System.unique_integer()}@example.com"
  def valid_worker_password, do: "hello world!"

  def valid_worker_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      pseudo: "Some pseudo",
      email: unique_worker_email(),
      password: valid_worker_password()
    })
  end

  def worker_fixture(attrs \\ %{}) do
    {:ok, worker} =
      attrs
      |> valid_worker_attributes()
      |> Tasker.Accounts.register_worker()

    worker
  end

  def extract_worker_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end
end
