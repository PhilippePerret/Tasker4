defmodule TaskerWeb.TaskController do
  use TaskerWeb, :controller

  alias Tasker.{Repo, Tache}
  alias Tasker.Tache.Task

  def index(conn, _params) do
    tasks = Tache.list_tasks() |> Repo.preload(:project)
    render(conn, :index, tasks: tasks)
  end

  defp common_render(conn, changeset, action) do
    conn
    |> assign(:projects, Tasker.Projet.list_projects())
    |> assign(:changeset, changeset)
    |> render(action)
  end

  def new(conn, _params) do
    common_render(conn, Tache.change_task(%Task{}), :new)
  end
  
  def edit(conn, %{"id" => id}) do
    common_render(conn, Tache.get_task!(id) |> Tache.change_task(), :edit)
  end

  def create(conn, %{"task" => task_params}) do
    project_id = case task_params["new_project"] do
      "" -> task_params["project_id"] # Rien n'est saisi, on garde project_id normal
      new_title -> 
        {:ok, project} = Tasker.Projet.create_project(%{title: new_title})
        project.id
    end
  
    updated_params = Map.put(task_params, "project_id", project_id)
  
    case Tache.create_task(updated_params) do
      {:ok, task} ->
        conn
        |> put_flash(:info, "Task created successfully.")
        |> redirect(to: ~p"/tasks/#{task}")
  
      {:error, %Ecto.Changeset{} = changeset} ->
        projects = Tasker.Projet.list_projects() || []
        render(conn, :new, changeset: changeset, projects: projects)
    end
  end
  
  def show(conn, %{"id" => id}) do
    task = Tache.get_task!(id) |> Repo.preload(:project)
    render(conn, :show, task: task)
  end


  def update(conn, %{"id" => id, "task" => task_params}) do
    task = Tache.get_task!(id)

    case Tache.update_task(task, task_params) do
      {:ok, task} ->
        conn
        |> put_flash(:info, dgettext("tasker", "Task updated successfully."))
        |> redirect(to: ~p"/tasks/#{task}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, task: task, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    task = Tache.get_task!(id)
    {:ok, _task} = Tache.delete_task(task)

    conn
    |> put_flash(:info, dgettext("tasker", "Task deleted successfully."))
    |> redirect(to: ~p"/tasks")
  end

end
