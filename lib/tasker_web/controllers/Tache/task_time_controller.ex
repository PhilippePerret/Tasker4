defmodule TaskerWeb.TaskTimeController do
  use TaskerWeb, :controller

  alias Tasker.Tache
  alias Tasker.Tache.TaskTime

  def index(conn, _params) do
    task_times = Tache.list_task_times()
    render(conn, :index, task_times: task_times)
  end

  def new(conn, _params) do
    changeset = Tache.change_task_time(%TaskTime{})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"task_time" => task_time_params}) do
    case Tache.create_task_time(task_time_params) do
      {:ok, task_time} ->
        conn
        |> put_flash(:info, "Task time created successfully.")
        |> redirect(to: ~p"/task_times/#{task_time}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    task_time = Tache.get_task_time!(id)
    render(conn, :show, task_time: task_time)
  end

  def edit(conn, %{"id" => id}) do
    task_time = Tache.get_task_time!(id)
    changeset = Tache.change_task_time(task_time)
    render(conn, :edit, task_time: task_time, changeset: changeset)
  end

  def update(conn, %{"id" => id, "task_time" => task_time_params}) do
    task_time = Tache.get_task_time!(id)

    case Tache.update_task_time(task_time, task_time_params) do
      {:ok, task_time} ->
        conn
        |> put_flash(:info, "Task time updated successfully.")
        |> redirect(to: ~p"/task_times/#{task_time}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, task_time: task_time, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    task_time = Tache.get_task_time!(id)
    {:ok, _task_time} = Tache.delete_task_time(task_time)

    conn
    |> put_flash(:info, "Task time deleted successfully.")
    |> redirect(to: ~p"/task_times")
  end
end
