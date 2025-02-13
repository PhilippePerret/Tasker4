defmodule TaskerWeb.TaskController do
  use TaskerWeb, :controller

  alias Tasker.{Repo, Tache}
  alias Tasker.Tache.{Task, TaskSpec}

  def index(conn, _params) do
    tasks = Tache.list_tasks() |> Repo.preload(:project)
    render(conn, :index, tasks: tasks)
  end

  defp common_render(conn, action, task_id) do
    changeset_task = 
      if action == :new do
        Tache.change_task(%Task{})
      else
        Tache.get_task!(task_id) |> Tache.change_task()
      end
    changeset_spec = 
      if action == :new do
        Tache.change_task_spec(%TaskSpec{})
      else
        Tache.get_task_spec_by_task_id!(task_id) |> Tache.change_task_spec()
      end
    conn
    |> assign(:projects, Tasker.Projet.list_projects())
    |> assign(:changeset, changeset_task)
    # |> assign(:changeset_spec, changeset_spec)
    |> render(action)
  end

  def new(conn, _params) do
    common_render(conn, :new, nil)
  end
  
  def edit(conn, %{"id" => id}) do
    common_render(conn, :edit, id)
  end

  def create(conn, %{"task" => task_params}) do
    # IO.inspect(task_params, label: "Task Params")
    project_id =
    case task_params["new_project"] do
      "" -> task_params["project_id"]  # Rien n'est saisi, on garde project_id normal
      new_title ->
        case Tasker.Projet.create_project(%{title: new_title}) do
          {:ok, project} -> project.id
          {:error, changeset} ->
            projects = Tasker.Projet.list_projects() || []
            render(conn, :new, changeset: changeset, projects: projects)
            throw(:abort)  # On interrompt l'exécution ici
        end
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
