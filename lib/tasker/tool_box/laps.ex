defmodule Tasker.ToolBox.Laps do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "laps" do
    field :start, :naive_datetime
    field :stop, :naive_datetime
    field :task_id, :binary_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(laps, attrs) do
    laps
    |> cast(attrs, [:start, :stop])
    |> validate_required([:start, :stop])
  end
end
