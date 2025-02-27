# Pour insérer ces données minimales : 
# 
#     mix run priv/repo/seeds/minimal.exs

defmodule Tasker.Seed do

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
    Tasker.Tache.create_task(data_task)
    # Dépendances 
    # TODO
    # Natures
    # TODO
    # Table task_states
    # TODO
  end
end

alias Tasker.Seed, as: S

phil_data = %{
  pseudo: "Phil",
  email: "philippe.perret@yahoo.fr",
  password: "xadcaX-huvdo9-xidkun"
}
S.insert(:worker, phil_data)

task = S.insert(:task, %{
  project: %{title: "Tout premier projet"},
  task: %{title: "Toute première tâche"}
})
IO.inspect(task, label: "\nPremière tâche")