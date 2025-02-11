defmodule TaskerWeb.WorkerConfirmationController do
  use TaskerWeb, :controller

  alias Tasker.Accounts

  def new(conn, _params) do
    render(conn, :new)
  end

  def create(conn, %{"worker" => %{"email" => email}}) do
    if worker = Accounts.get_worker_by_email(email) do
      Accounts.deliver_worker_confirmation_instructions(
        worker,
        &url(~p"/workers/confirm/#{&1}")
      )
    end

    conn
    |> put_flash(
      :info,
      "If your email is in our system and it has not been confirmed yet, " <>
        "you will receive an email with instructions shortly."
    )
    |> redirect(to: ~p"/")
  end

  def edit(conn, %{"token" => token}) do
    render(conn, :edit, token: token)
  end

  # Do not log in the worker after confirmation to avoid a
  # leaked token giving the worker access to the account.
  def update(conn, %{"token" => token}) do
    case Accounts.confirm_worker(token) do
      {:ok, _} ->
        conn
        |> put_flash(:info, "Worker confirmed successfully.")
        |> redirect(to: ~p"/")

      :error ->
        # If there is a current worker and the account was already confirmed,
        # then odds are that the confirmation link was already visited, either
        # by some automation or by the worker themselves, so we redirect without
        # a warning message.
        case conn.assigns do
          %{current_worker: %{confirmed_at: confirmed_at}} when not is_nil(confirmed_at) ->
            redirect(conn, to: ~p"/")

          %{} ->
            conn
            |> put_flash(:error, "Worker confirmation link is invalid or it has expired.")
            |> redirect(to: ~p"/")
        end
    end
  end
end
