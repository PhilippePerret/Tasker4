defmodule TaskerWeb.WorkerResetPasswordController do
  use TaskerWeb, :controller

  alias Tasker.Accounts

  plug :get_worker_by_reset_password_token when action in [:edit, :update]

  def new(conn, _params) do
    render(conn, :new)
  end

  def create(conn, %{"worker" => %{"email" => email}}) do
    if worker = Accounts.get_worker_by_email(email) do
      Accounts.deliver_worker_reset_password_instructions(
        worker,
        &url(~p"/workers/reset_password/#{&1}")
      )
    end

    conn
    |> put_flash(
      :info,
      gettext("If your email is in our system, you will receive instructions to reset your password shortly.")
    )
    |> redirect(to: ~p"/")
  end

  def edit(conn, _params) do
    render(conn, :edit, changeset: Accounts.change_worker_password(conn.assigns.worker))
  end

  # Do not log in the worker after reset password to avoid a
  # leaked token giving the worker access to the account.
  def update(conn, %{"worker" => worker_params}) do
    case Accounts.reset_worker_password(conn.assigns.worker, worker_params) do
      {:ok, _} ->
        conn
        |> put_flash(:info, gettext("Password reset successfully."))
        |> redirect(to: ~p"/workers/log_in")

      {:error, changeset} ->
        render(conn, :edit, changeset: changeset)
    end
  end

  defp get_worker_by_reset_password_token(conn, _opts) do
    %{"token" => token} = conn.params

    if worker = Accounts.get_worker_by_reset_password_token(token) do
      conn |> assign(:worker, worker) |> assign(:token, token)
    else
      conn
      |> put_flash(:error, gettext("Reset password link is invalid or it has expired."))
      |> redirect(to: ~p"/")
      |> halt()
    end
  end
end
