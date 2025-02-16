defmodule Tasker.Tache.NoteTaskSpec do
  use Ecto.Schema

  schema "notes_tasks" do
    belongs_to :task_spec, Tasker.Tache.TaskSpec
    belongs_to :note, Tasker.ToolBox.Note
    timestamps(type: :utc_datetime)
  end
end