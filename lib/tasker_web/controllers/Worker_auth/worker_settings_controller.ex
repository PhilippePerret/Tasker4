defmodule TaskerWeb.WorkerSettingsController do
  use TaskerWeb, :controller

  alias Tasker.Accounts
  alias TaskerWeb.WorkerAuth

  plug :assign_email_and_password_changesets

  def edit(conn, _params) do
    render(conn, :edit)
  end

  def update(conn, %{"action" => "update_email"} = params) do
    %{"current_password" => password, "worker" => worker_params} = params
    worker = conn.assigns.current_worker

    case Accounts.apply_worker_email(worker, password, worker_params) do
      {:ok, applied_worker} ->
        Accounts.deliver_worker_update_email_instructions(
          applied_worker,
          worker.email,
          &url(~p"/workers/settings/confirm_email/#{&1}")
        )

        conn
        |> put_flash(
          :info,
          gettext("A link to confirm your email change has been sent to the new address.")
        )
        |> redirect(to: ~p"/workers/settings")

      {:error, changeset} ->
        render(conn, :edit, email_changeset: changeset)
    end
  end

  def update(conn, %{"action" => "update_password"} = params) do
    %{"current_password" => password, "worker" => worker_params} = params
    worker = conn.assigns.current_worker

    case Accounts.update_worker_password(worker, password, worker_params) do
      {:ok, worker} ->
        conn
        |> put_flash(:info, gettext("Password updated successfully."))
        |> put_session(:worker_return_to, ~p"/workers/settings")
        |> WorkerAuth.log_in_worker(worker)

      {:error, changeset} ->
        render(conn, :edit, password_changeset: changeset)
    end
  end

  def confirm_email(conn, %{"token" => token}) do
    case Accounts.update_worker_email(conn.assigns.current_worker, token) do
      :ok ->
        conn
        |> put_flash(:info, gettext("Email changed successfully."))
        |> redirect(to: ~p"/workers/settings")

      :error ->
        conn
        |> put_flash(:error, gettext("Email change link is invalid or it has expired."))
        |> redirect(to: ~p"/workers/settings")
    end
  end

  defp assign_email_and_password_changesets(conn, _opts) do
    worker = conn.assigns.current_worker

    conn
    |> assign(:email_changeset, Accounts.change_worker_email(worker))
    |> assign(:password_changeset, Accounts.change_worker_password(worker))
  end
end
