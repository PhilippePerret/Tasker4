defmodule TaskerWeb.WorkerSessionController do
  use TaskerWeb, :controller

  alias Tasker.Accounts
  alias TaskerWeb.WorkerAuth

  def new(conn, _params) do
    render(conn, :new, error_message: nil)
  end

  def create(conn, %{"worker" => worker_params}) do
    %{"email" => email, "password" => password} = worker_params

    if worker = Accounts.get_worker_by_email_and_password(email, password) do
      conn
      |> put_flash(:info, gettext("Welcome back!"))
      |> WorkerAuth.log_in_worker(worker, worker_params)
    else
      # In order to prevent user enumeration attacks, don't disclose whether the email is registered.
      render(conn, :new, error_message: gettext("Invalid email or password"))
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, gettext("Logged out successfully."))
    |> WorkerAuth.log_out_worker()
  end
end
