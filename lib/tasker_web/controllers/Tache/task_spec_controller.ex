defmodule TaskerWeb.TaskSpecController do
  use TaskerWeb, :controller

  alias Tasker.Tache
  alias Tasker.Tache.TaskSpec

  def index(conn, _params) do
    task_specs = Tache.list_task_specs()
    render(conn, :index, task_specs: task_specs)
  end

  def new(conn, _params) do
    changeset = Tache.change_task_spec(%TaskSpec{})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"task_spec" => task_spec_params}) do
    case Tache.create_task_spec(task_spec_params) do
      {:ok, task_spec} ->
        conn
        |> put_flash(:info, "Task spec created successfully.")
        |> redirect(to: ~p"/task_specs/#{task_spec}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    task_spec = Tache.get_task_spec!(id)
    render(conn, :show, task_spec: task_spec)
  end

  def edit(conn, %{"id" => id}) do
    task_spec = Tache.get_task_spec!(id)
    changeset = Tache.change_task_spec(task_spec)
    render(conn, :edit, task_spec: task_spec, changeset: changeset)
  end

  def update(conn, %{"id" => id, "task_spec" => task_spec_params}) do
    task_spec = Tache.get_task_spec!(id)

    case Tache.update_task_spec(task_spec, task_spec_params) do
      {:ok, task_spec} ->
        conn
        |> put_flash(:info, "Task spec updated successfully.")
        |> redirect(to: ~p"/task_specs/#{task_spec}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, task_spec: task_spec, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    task_spec = Tache.get_task_spec!(id)
    {:ok, _task_spec} = Tache.delete_task_spec(task_spec)

    conn
    |> put_flash(:info, "Task spec deleted successfully.")
    |> redirect(to: ~p"/task_specs")
  end
end
