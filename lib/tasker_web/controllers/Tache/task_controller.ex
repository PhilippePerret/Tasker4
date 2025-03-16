defmodule TaskerWeb.TaskController do
  use TaskerWeb, :controller

  import Ecto.Query

  alias Tasker.{Repo, Projet, Tache}
  alias Tasker.Tache.{Task, TaskSpec, TaskTime, TaskNature}
  alias Tasker.ToolBox
  # alias ToolBox.TaskScript

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
      create_or_update_scripts(task_params, task)
      conn
      |> put_flash(:info, dgettext("tasker", "Task created successfully."))
      |> redirect(to: ~p"/tasks/#{task}/edit")

    {:error, %Ecto.Changeset{} = _changeset} ->
      # On passe ici quand la création n'a pas pu se faire
      conn = conn 
      |> put_flash(:error, dgettext("tasker", "Please enter at least a title for the task!"))
      new(conn, nil)
  end
  end
  
  def show(conn, %{"id" => id}) do
    task = Tache.get_task!(id) |> Repo.preload(:project)
    render(conn, :show, task: task)
  end

  def update(conn, %{"id" => id, "task" => task_params} = _params) do
    task_params = task_params
    |> convert_string_values_to_real_values()
    # |> IO.inspect(label: "task_params après convert string")
    |> create_project_if_needed(conn)
    # |> IO.inspect(label: "task_params après création projet (si nécessaire)")
    |> create_or_update_scripts()
    # |> IO.inspect(label: "task_params après premiers traitements")

    task = Tache.get_task!(id)

    # Traiter les NATURES
    # Note : pour les nouvelles, il faut les mettre dans les préfé-
    # rences, mais ça serait bien de donner la possibilité d'en 
    # créer des nouvelles dans le formulaire (champ qui servirait 
    # aussi à les sélectionner dans la liste)
    param_natures = task_params["natures"]
    task_params = 
    if param_natures && param_natures != "" && param_natures != [] do
      list_of_natures = task_params["natures"]
      |> String.split(",")
      |> Enum.map(fn nat_id ->
        Repo.one!(from nt in TaskNature, where: nt.id == ^nat_id)
      end)
      # |> IO.inspect(label: "Structures natures")
      Map.put(task_params, "natures", list_of_natures)
    else task_params end

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

  @doc """
  À la création ou l'actualisation de la tâche, on regarde si un 
  nouveau projet a été défini. Si c'est le cas, on le crée.

  @return {Map} La liste des paramètres de création/update de la
  tâche.
  """
  def create_project_if_needed(task_params, conn) do
    project_id =
      case task_params["new_project"] do
        nil -> 
          # Pas de nouveau titre
          task_params["project_id"]
        new_title ->
          # Un nouveau titre
          case Tasker.Projet.create_project(%{title: new_title}) do
            {:ok, project} -> project.id
            {:error, _changeset} ->
              new(conn, nil)
              throw(:abort)  # On interrompt l'exécution ici
          end
      end  
    Map.put(task_params, "project_id", project_id)
  end


  @doc """
  Fonction qui crée au besoin les scripts associés à la tâche à 
  enregistrer ou updater.

  @return {Map} La table des paramètres d'enregistrement, sans
  aucun changement ici puisque seul le script porte la marque de la
  tâche, mais pas l'inverse.
  """
  def create_or_update_scripts(%{"task-scripts" => task_scripts} = task_params, %Task{} = task) do
    if task_params["erased-scripts"] && task_params["erased-scripts"] != "" do
      # S'il y a des scripts à détruire
      task_params["erased-scripts"]
      |> String.split(";")
      |> ToolBox.delete_scripts()
    end

    if task_scripts do
      data_scripts = Jason.decode!(task_scripts)
      # IO.inspect(data_scripts, label: "Données pour les script")

      if data_scripts do
        data_scripts
        |> Enum.map(fn dscript ->
          # Un nouveau script
          data_script = Enum.reduce(dscript, %{}, fn {key, value}, accu ->
            if key == "id" and dscript["id"] == "" do
              accu
            else
              Map.put(accu, String.to_atom(key), value)
            end
          end) |> Map.merge(%{task_id: task.id})
          script_id =
          if dscript["id"] == "" do
            # IO.inspect(data_script, label: "data script")
            new_script = ToolBox.create_task_script(data_script)
            new_script.id
          else 
            ToolBox.update_task_script(data_script)
            data_script.id
          end
          %{ dscript | "id" => script_id }
        end)
      end
      # IO.inspect(data_scripts, label: "Données scripts APRÈS")
    end

    # Pour la suite
    task_params
  end
  
  def create_or_update_scripts(task_params, _task), do: task_params
  
  def create_or_update_scripts(%{"task-scripts" => _task_scripts} = task_params) do
    create_or_update_scripts(task_params, Tache.get_task!(task_params["id"]))
  end



  defp common_render(conn, :new) do
    task_changeset = %Task{
      task_spec: %TaskSpec{notes: []},
      task_time: %TaskTime{},
      project: %Projet.Project{},
      natures: []
    } |> Ecto.Changeset.change()
    common_conn_render(conn, :new, task_changeset)
  end

  defp common_render(conn, action, task_id) do
    task_changeset = Tache.get_task!(task_id) |> Tache.change_task()
    common_conn_render(conn, action, task_changeset)
  end

  defp common_conn_render(conn, action, task_changeset) do

    data = %{
      natures: get_list_natures(conn.assigns.current_worker)
    }

    natures_string = task_changeset.data.natures |> Enum.map(& &1.id) |> Enum.join(",")
    task_changeset = %{task_changeset | data: %{task_changeset.data | natures: natures_string}}

    conn
    |> assign(:projects, Tasker.Projet.list_projects())
    |> assign(:data, data)
    |> assign(:task, (action == :new) && nil || task_changeset.data)
    |> assign(:changeset, task_changeset)
    |> assign(:lang, Gettext.get_locale(TaskerWeb.Gettext))
    |> render(action)
  end

  defp convert_string_values_to_real_values(attrs) do
    attrs
    |> convert_nil_string_values()
  end

  @defaul_values_per_key %{
    "natures" => []
  }
  defp convert_nil_string_values(attrs) do
    Enum.into(attrs, %{}, fn 
      {k, "nil"} -> {k, nil}
      {k, ""} -> {k, Map.get(@defaul_values_per_key, k, nil)}
      {k, "[]"} -> {k, nil}
      {k, %{} = map} -> {k, convert_nil_string_values(map)}
      pair -> pair
    end)
  end

  @doc """
  Retourne la liste des natures.
  Elles ont deux sources :
    - la liste des natures systèmes (dans la table task_natures)
    - les natures personnalisées par le travailleur, dans sa fiche
      worker_settings
  """
  def get_list_natures(current_worker) do
    Map.merge(
      (Tache.list_natures()
      |> Enum.reduce(%{}, fn nature, accu ->
        Map.put(accu, nature.id, nature.name)
      end)
      ),
      (
        (Tasker.Accounts.get_worker_settings(current_worker.id)
        .task_prefs[:custom_natures] || [])
        |> Enum.reduce(%{}, fn {nature_id, nature_name}, accu ->
          Map.put(accu, nature_id, nature_name)
        end)
      )
    )
  end
end
