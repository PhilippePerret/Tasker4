defmodule Tasker.ToolBox.Note do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "notes" do
    field :title, :string
    field :details, :string
    belongs_to :author, Tasker.Worker
    many_to_many :task_specs, Tasker.Tache.TaskSpec, join_through: "notes_tasks"

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(note, attrs) do
    note
    |> cast(attrs, [:title, :details])
    |> validate_required([:title])
  end
end
