defmodule Tasker.Tache.NoteTaskSpec do
  use Ecto.Schema

  @primary_key false  # Désactive la clé primaire par défaut
  schema "notes_tasks" do
    belongs_to :task_spec, Tasker.Tache.TaskSpec, type: :binary_id
    belongs_to :note, Tasker.ToolBox.Note, type: :binary_id
    timestamps(type: :utc_datetime)
  end
end