defmodule Tasker.Tache.TaskRank do
  defstruct [
    value:        0,
    index:        nil,     
    live_index:   nil,
    calc_at:      nil,
    remoteness:   nil   # laps de temps, en minutes, qui sépare de la tâche
  ]
end