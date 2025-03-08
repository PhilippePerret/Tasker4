# Pour insérer ces données minimales : 
# 
#     mix run priv/repo/seeds/minimal.exs

ExUnit.start()
Code.require_file("data_case.ex", "./test/support")
Code.require_file("random_methods.ex", "./test/support/fixtures")
Code.require_file("tache_fixtures.ex", "./test/support/fixtures")
Code.require_file("projet_fixtures.ex", "./test/support/fixtures")
defmodule Tasker.Seed do

  alias Tasker.TacheFixtures, as: FXT
  alias Tasker.ProjetFixtures, as: FXP

  def truncate(:tasks) do
    Tasker.Repo.delete_all(Tasker.Tache.TaskSpec)
    Tasker.Repo.delete_all(Tasker.Tache.TaskTime)
    Tasker.Repo.delete_all(Tasker.Tache.Task)
    Tasker.Repo.delete_all("tasks_natures")
  end
  def truncate(:projects) do
    Tasker.Repo.delete_all(Tasker.Projet.Project)
  end

  def insert(:worker, attrs) do
    attrs = Map.put(attrs, :hashed_password, Bcrypt.hash_pwd_salt(attrs.password))
    Tasker.Accounts.create_worker(attrs)
    # Tasker.Repo.insert!(struct(Tasker.Accounts.Worker, attrs))
  end
  def insert(:project, attrs) do
    Tasker.Repo.insert!(struct(Tasker.Projet.Project, attrs))
  end
  def insert(:task_spec, attrs) do
    Tasker.Repo.insert!(struct(Tasker.Tache.TaskSpec, attrs))
  end
  def insert(:task_time, attrs) do
    Tasker.Repo.insert!(struct(Tasker.Tache.TaskTime, attrs))
  end

  @doc """
  Création d'une tâche

  @return {%Task} La tâche créée.
  """
  def insert(:task, attrs) do
    FXT.create_task(attrs)
  end

  def insertion_people do
    phil_data = %{
      pseudo: "Phil",
      email: "philippe.perret@yahoo.fr",
      password: "xadcaX-huvdo9-xidkun"
    }
    insert(:worker, phil_data)
  end

  def insertion_une do
    task = insert(:task, %{
      title: "Toute première tâche",
      project: true,
    })
  end

  
  def insertion_quatre_with_dependances do
    projet = insert(:project)
    task1 = insert(:task, %{
      project: projet.id,
      title: "Une tâche avec une tâche après",
      natures: ["purchases", "ana_film"]
    })
    task2 = insert(:task, %{
      project: projet.id,
      title: "La tâche qui suit la tâche avant",
      natures: ["drama"],
      after: task1
    })

    projet = insert(:project)
    task1 = insert(:task, %{
      project: projet.id,
      title: "Une autre tâche avec une tâche après"
    })
    task2 = insert(:task, %{
      project: projet.id,
      title: "La autre tâche qui suit la tâche avant",
      after: task1
    })
  end

  def insertion_dix_diverses do
    ids_de_projets = project_ids([create_if_empty: true])
    FXT.create_tasks(10, %{project: ids_de_projets})
  end

  defp project_ids(options \\ []) do
    project_list() 
    |> create_projects_if_empty(options)
    |> Enum.map(fn p -> p.id end)
  end

  defp project_list do
    Tasker.Projet.list_projects()
  end

  defp create_projects_if_empty(liste, options) do
    if 0 === Enum.count(liste) and true === options[:create_if_empty] do
      FXP.create_projects(3)
    else liste end
  end
    
end
  
alias Tasker.Seed, as: S

# === Workers ===
# S.insertion_people()

# === tâches ===
S.truncate(:tasks)
S.truncate(:projects)
S.insertion_une()
S.insertion_quatre_with_dependances()
S.insertion_dix_diverses()