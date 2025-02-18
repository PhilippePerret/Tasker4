defmodule TaskerWeb.TaskController do
  use TaskerWeb, :controller

  alias Tasker.{Repo, Tache}
  alias Tasker.Tache.{Task, TaskSpec, TaskTime}

  def index(conn, _params) do
    tasks = Tache.list_tasks() |> Repo.preload(:project)
    conn
    |> assign(:tasks, tasks)
    |> assign(:orientation, "paysage")
    |> render(:index)
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
    task_params = task_params
    |> convert_string_values_to_real_values()
    |> create_project_if_needed(conn)
  
    case Tache.create_task(task_params) do
    {:ok, task} ->
      conn
      |> put_flash(:info, dgettext("tasker", "Task created successfully."))
      |> redirect(to: ~p"/tasks/#{task}/edit")

    {:error, %Ecto.Changeset{} = changeset} ->
      # On passe ici quand la création n'a pas pu se faire
      projects = Tasker.Projet.list_projects() || []
      conn = conn 
      |> put_flash(:error, dgettext("tasker", "Please enter at least a title for the task!"))
      new(conn, nil)
  end
  end
  
  def show(conn, %{"id" => id}) do
    task = Tache.get_task!(id) |> Repo.preload(:project)
    render(conn, :show, task: task)
  end


  def update(conn, %{"id" => id, "task" => task_params}) do
    IO.inspect(task_params, label: "-> update")
    task_params = task_params
    |> convert_string_values_to_real_values()
    |> create_project_if_needed(conn)
    |> IO.inspect(label: "\nParamp à l'entrée de update")

    task = Tache.get_task!(id)

    case Tache.update_task(task, task_params) do
      {:ok, task} ->
        conn
        |> put_flash(:info, dgettext("tasker", "Task updated successfully."))
        |> redirect(to: ~p"/tasks/#{task}/edit")

      {:error, %Ecto.Changeset{} = changeset} ->
        common_conn_render(conn, :edit, changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    task = Tache.get_task!(id)
    {:ok, _task} = Tache.delete_task(task)

    conn
    |> put_flash(:info, dgettext("tasker", "Task deleted successfully."))
    |> redirect(to: ~p"/tasks")
  end


  # ----- Functional Methods -----

  def create_project_if_needed(task_params, conn) do
    project_id =
      case task_params["new_project"] do
        "" -> 
          # Pas de nouveau titre
          task_params["project_id"]
        new_title ->
          # Un nouveau titre
          case Tasker.Projet.create_project(%{title: new_title}) do
            {:ok, project} -> project.id
            {:error, changeset} ->
              projects = Tasker.Projet.list_projects() || []
              new(conn, nil)
              throw(:abort)  # On interrompt l'exécution ici
          end
      end  
    Map.put(task_params, "project_id", project_id)
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
    ensure_fichier_locales_JS()
    conn
    |> assign(:projects, Tasker.Projet.list_projects())
    |> assign(:task, (action == :new) && nil || task_changeset.data)
    |> assign(:changeset, task_changeset)
    |> assign(:lang, Gettext.get_locale(TaskerWeb.Gettext))
    |> render(action)
  end

  defp convert_string_values_to_real_values(attrs) do
    attrs
    |> convert_nil_string_values()
  end
  defp convert_nil_string_values(attrs) do
    Enum.into(attrs, %{}, fn 
      {k, "nil"} -> {k, nil}
      {k, %{} = map} -> {k, convert_nil_string_values(map)}
      pair -> pair
    end)
  end


  @doc """
  Fonction préparant le fichier /priv/static/assets/js/locales.js qui
  contient les locales utiles aux messages du fichier javascript.
  Pour le moment, on ne l'actualise que lorsqu'il n'existe pas. Il 
  suffit de décommenter la première ligne pour le détruire et le re-
  faire
  """
  @locale_js_path Path.expand(Path.join(["priv","static","assets","js","locales-LANG.js"]))
  @locales {nil, []}
  @locales_tasker {"tasker", ["Repeat this task"]}
  @locales_ilya {"ilya", ~w(monday tuesday wednesday thursday friday saturday sunday every) ++ ["on (day)"]}
  defp ensure_fichier_locales_JS do
    IO.puts "-> ensure_fichier_locales_JS"
    locale_js_path = String.replace(@locale_js_path, "LANG", Gettext.get_locale(TaskerWeb.Gettext))
    IO.inspect(locale_js_path, label: "\nlocale_js_path")
    if not File.exists?(locale_js_path) do
      IO.puts "FABRICATION DU FICHIER LOCALE.JS"
      table_locale = [@locales, @locales_ilya, @locales_tasker]
      |> Enum.reduce(%{}, fn {domain, locales}, accu1 ->
        sous_table =
          Enum.reduce(locales, accu1, fn locale, accu2 ->
            if domain do
              Map.put(accu2, "#{domain}-#{locale}", Gettext.dgettext(TaskerWeb.Gettext, domain, locale))
            else
              Map.put(accu2, locale, Gettext.gettext(TaskerWeb.Gettext, locale))
            end
          end)
        Map.merge(accu1, sous_table)
      end)
      |> Jason.encode!()
      IO.inspect(table_locale, label: "\ntable_locale")
      File.write(locale_js_path, "const LANG = " <> table_locale)
    end
  end

end
