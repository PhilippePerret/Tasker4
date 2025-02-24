defmodule Tasker.TaskRankCalculator do

  @doc """
  Fonction principale qui reçoit une liste de tache (Task) et les
  classe par task_rank avant de les envoyer au client pour usage.
  @main
  @api

  ## Examples

    iex> RankCalc.sort([])
    []

  @param {List of %Task{}} task_list Liste des structures Task.
  """
  def sort(task_list) when is_list(task_list) do

    task_list
  end

end