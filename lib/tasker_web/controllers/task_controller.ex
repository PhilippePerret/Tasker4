defmodule TaskerWeb.TaskController do
  use TaskerWeb, :controller

  alias Tasker.{Repo, Tache}
  alias Tasker.Tache.Task

  def index(conn, _params) do
    tasks = Tache.list_tasks()
    render(conn, :index, tasks: tasks)
  end

  def new(conn, _params) do
    changeset = Tache.change_task(%Task{})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"task" => task_params}) do
    case Tache.create_task(task_params) do
      {:ok, task} ->
        conn
        |> put_flash(:info, "Task created successfully.")
        |> redirect(to: ~p"/tasks/#{task}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    task = Tache.get_task!(id) |> Repo.preload(:project)
    render(conn, :show, task: task)
  end

  def edit(conn, %{"id" => id}) do
    task = Tache.get_task!(id)
    changeset = Tache.change_task(task)
    render(conn, :edit, task: task, changeset: changeset)
  end

  def update(conn, %{"id" => id, "task" => task_params}) do
    task = Tache.get_task!(id)

    case Tache.update_task(task, task_params) do
      {:ok, task} ->
        conn
        |> put_flash(:info, "Task updated successfully.")
        |> redirect(to: ~p"/tasks/#{task}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, task: task, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    task = Tache.get_task!(id)
    {:ok, _task} = Tache.delete_task(task)

    conn
    |> put_flash(:info, "Task deleted successfully.")
    |> redirect(to: ~p"/tasks")
  end
end
