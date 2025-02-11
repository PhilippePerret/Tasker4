defmodule TaskerWeb.WorkerController do
  use TaskerWeb, :controller

  alias Tasker.Accounts
  alias Tasker.Accounts.Worker

  def index(conn, _params) do
    workers = Accounts.list_workers()
    render(conn, :index, workers: workers)
  end

  def new(conn, _params) do
    changeset = Accounts.change_worker(%Worker{})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"worker" => worker_params}) do
    case Accounts.create_worker(worker_params) do
      {:ok, worker} ->
        conn
        |> put_flash(:info, "Worker created successfully.")
        |> redirect(to: ~p"/workers/#{worker}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    worker = Accounts.get_worker!(id)
    render(conn, :show, worker: worker)
  end

  def edit(conn, %{"id" => id}) do
    worker = Accounts.get_worker!(id)
    changeset = Accounts.change_worker(worker)
    render(conn, :edit, worker: worker, changeset: changeset)
  end

  def update(conn, %{"id" => id, "worker" => worker_params}) do
    worker = Accounts.get_worker!(id)

    case Accounts.update_worker(worker, worker_params) do
      {:ok, worker} ->
        conn
        |> put_flash(:info, "Worker updated successfully.")
        |> redirect(to: ~p"/workers/#{worker}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, worker: worker, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    worker = Accounts.get_worker!(id)
    {:ok, _worker} = Accounts.delete_worker(worker)

    conn
    |> put_flash(:info, "Worker deleted successfully.")
    |> redirect(to: ~p"/workers")
  end
end
