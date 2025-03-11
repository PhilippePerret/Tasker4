defmodule Tasker.ToolBox.Note do
  use Ecto.Schema
  import Ecto.Changeset

  alias Tasker.Tache.NoteTaskSpec

  @derive {Jason.Encoder, only: [:id, :title, :details, :author, :inserted_at]}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "notes" do
    field :title, :string
    field :details, :string
    belongs_to :author, Tasker.Accounts.Worker
    many_to_many :task_specs, Tasker.Tache.TaskSpec, join_through: NoteTaskSpec

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(note, attrs) do
    note
    |> cast(attrs, [:title, :details, :author_id])
    |> validate_required([:title, :author_id])
    |> put_change(:author_id, Map.get(attrs, :author_id))
    |> validate_length(:title, min: 5, max: 255)
  end
end
