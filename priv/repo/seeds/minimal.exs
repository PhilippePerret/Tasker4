# Pour insérer ces données minimales : 
# 
#     mix run priv/repo/seeds/minimal.exs

defmodule Tasker.Seed do

  def truncate(:tasks) do
    Tasker.Repo.delete_all(Tasker.Tache.TaskSpec)
    Tasker.Repo.delete_all(Tasker.Tache.TaskTime)
    Tasker.Repo.delete_all(Tasker.Tache.Task)
    Tasker.Repo.delete_all("tasks_natures")
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

  def insert(:task, attrs) do
    # Projet ?
    data_task =
      if attrs.project do
        project = insert(:project, attrs.project)
        Map.put(attrs.task, :project_id, project.id)
      else
        attrs.task
      end
    # La tâche
    {:ok, task} = Tasker.Tache.create_task(data_task)
    # Dépendances 
    if attrs[:after] do
      Enum.each(attrs[:after], fn task_before -> 
        Tasker.Tache.create_dependency(task_before, task)
      end)
    end
    if attrs[:before] do
      Enum.each(attrs[:after], fn task_after -> 
        Tasker.Tache.create_dependency(task, task_after)
      end)
    end

    # Natures
    if attrs[:natures] do
      Tasker.Tache.inject_natures(task, attrs[:natures])
    end

    # Table task_states
    # TODO

    # On retourne la tâche
    task
  end

  def insertion_un do
    phil_data = %{
      pseudo: "Phil",
      email: "philippe.perret@yahoo.fr",
      password: "xadcaX-huvdo9-xidkun"
    }
    insert(:worker, phil_data)

    task = insert(:task, %{
      project: %{title: "Tout premier projet"},
      task: %{title: "Toute première tâche"}
      })
    IO.inspect(task, label: "\nPremière tâche")
  end

  
  def insertion_deux do
    task1 = insert(:task, %{
      project: %{title: "Tout premier projet"},
      task: %{
        title: "Une tâche avec une tâche après"
      },
      natures: ["purchases", "ana_film"]
    })
    task2 = insert(:task, %{
      project: %{title: "Tout premier projet"},
      task: %{
        title: "La tâche qui suit la tâche avant"
      },
      natures: ["drama"],
      after: [task1]
    })
  end
    
  def insertion_trois do
    task1 = insert(:task, %{
      project: %{title: "Tout premier projet"},
      task: %{title: "Une autre tâche avec une tâche après"}
    })
    task2 = insert(:task, %{
      project: %{title: "Tout premier projet"},
      task: %{title: "La autre tâche qui suit la tâche avant"},
    after: [task1]
    })
  end
    
end
  
alias Tasker.Seed, as: S

# S.insertion_un()

# === tâches ===
S.truncate(:tasks)
S.insertion_deux()
S.insertion_trois()