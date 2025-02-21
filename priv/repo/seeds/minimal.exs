# Pour insérer ces données minimales : 
# 
#     mix run priv/repo/seeds/minimal.exs

defmodule Tasker.Seed do

  def insert(:worker, attrs) do
    Tasker.Repo.insert!(struct(Tasker.Worker, attrs))
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
    task  = Tasker.Repo.insert!(struct(Tasker.Tache.Task, attrs.task))
    if attrs[:task_spec] do
      insert(:task_spec, Map.put(attrs.task_spec, :task_id, task.id))
    end
    if attrs[:task_time] do
      insert(:task_time, Map.put(attrs.task_time, :task_id, task.id))
    end
    # Dépendances 
    # TODO
    # Natures
    # TODO
    # Table task_states
    # TODO
  end
end

alias Tasker.Seed, as: S


S.insert(:task, %{
  project: %{title: "Tout premier projet"},
  task: %{title: "Toute première tâche"}
})
