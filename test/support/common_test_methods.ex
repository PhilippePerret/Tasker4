defmodule CommonTestMethods do

  def is_around(sujet, comp, tolerance) do
    sujet > comp - tolerance && sujet < comp + tolerance
  end


  @doc """
  Pour voir les tâches courantes en mode test
  """
  def debug_current_tasks(titre \\ "TÂCHES COURANTES") do
    current_tasks = 
    Tasker.Tache.list_tasks()
    |> Enum.map(fn task ->
      Tasker.Tache.get_task!(task.id)
    end)
    
    IO.inspect(current_tasks, label: "\n\n#{titre} (#{Enum.count(current_tasks)} tâches)")
  end

end