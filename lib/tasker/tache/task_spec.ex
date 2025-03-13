defmodule Tasker.Tache.TaskSpec do
  use Ecto.Schema
  import Ecto.Changeset
  
  alias Tasker.Tache.NoteTaskSpec

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "task_specs" do
    field :details, :string
    field :priority, :integer
    field :urgence, :integer
    field :difficulty, :integer
    belongs_to :task, Tasker.Tache.Task
    many_to_many :notes, Tasker.ToolBox.Note, join_through: NoteTaskSpec

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(task_spec, attrs) do
    task_spec
    |> cast(attrs, [:details, :task_id, :priority, :urgence, :difficulty])
    |> validate_required([:task_id])
  end

end
