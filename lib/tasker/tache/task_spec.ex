defmodule Tasker.Tache.TaskSpec do
  use Ecto.Schema
  import Ecto.Changeset
  
  alias Tasker.Tache.NoteTaskSpec

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "task_specs" do
    field :details, :string
    belongs_to :task, Tasker.Tache.Task
    many_to_many :notes, Tasker.ToolBox.Note, join_through: NoteTaskSpec

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(task_spec, attrs) do
    task_spec
    |> cast(attrs, [:details, :task_id])
    |> validate_required([:task_id])
  end
end
