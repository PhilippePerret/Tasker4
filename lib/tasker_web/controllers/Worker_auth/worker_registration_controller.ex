defmodule TaskerWeb.WorkerRegistrationController do
  use TaskerWeb, :controller

  alias Tasker.Accounts
  alias Tasker.Accounts.Worker
  alias TaskerWeb.WorkerAuth

  def new(conn, _params) do
    changeset = Accounts.change_worker_registration(%Worker{})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"worker" => worker_params}) do
    case Accounts.create_worker(worker_params) do
      {:ok, worker} ->
        {:ok, _} =
          Accounts.deliver_worker_confirmation_instructions(
            worker,
            &url(~p"/workers/confirm/#{&1}")
          )

        conn
        |> put_flash(:info, gettext("Worker created successfully."))
        |> WorkerAuth.log_in_worker(worker)

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end
end
