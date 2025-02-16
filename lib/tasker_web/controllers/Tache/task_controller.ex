defmodule TaskerWeb.TaskController do
  use TaskerWeb, :controller

  alias Tasker.{Repo, Tache}
  alias Tasker.Tache.{Task, TaskSpec, TaskTime}

  def index(conn, _params) do
    tasks = Tache.list_tasks() |> Repo.preload(:project)
    conn
    |> assign(:tasks, tasks)
    |> assign(:orientation, "paysage")
    |> render(:liste)
  end

  defp common_render(conn, :new) do
    task_changeset = %Task{
      task_spec: %TaskSpec{notes: []},
      task_time: %TaskTime{}
    } |> Ecto.Changeset.change()
    common_conn_render(conn, :new, task_changeset)
  end

  defp common_render(conn, action, task_id) do
    task_changeset = Tache.get_task!(task_id) |> Tache.change_task()
    common_conn_render(conn, action, task_changeset)
  end

  defp common_conn_render(conn, action, task_changeset) do
    conn
    |> assign(:projects, Tasker.Projet.list_projects())
    |> assign(:task, (action == :new) && nil || task_changeset.data)
    |> assign(:changeset, task_changeset)
    |> render(action)
  end

  defp convert_string_values_to_real_values(attrs) do
    attrs
    |> convert_nil_string_values()
  end
  defp convert_nil_string_values(attrs) do
    Enum.into(attrs, %{}, fn 
      {k, "nil"} -> {k, nil}
      pair -> pair
    end)
  end

  # ---- Méthodes d'action -----

  def new(conn, _params) do
    common_render(conn, :new)
  end
  
  def edit(conn, %{"id" => id}) do
    common_render(conn, :edit, id)
  end

  def create(conn, %{"task" => task_params}) do
    # IO.inspect(task_params, label: "Task Params")
    task_params = convert_string_values_to_real_values(task_params)

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
        |> put_flash(:info, dgettext("tasker", "Task created successfully."))
        |> redirect(to: ~p"/tasks/#{task}/edit")
  
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
    task_params = convert_string_values_to_real_values(task_params)
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
