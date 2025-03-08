defmodule Tasker.ToolBox.Laps do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  @foreign_key_type :binary_id
  schema "laps" do
    field :start, :naive_datetime
    field :stop, :naive_datetime
    belongs_to :task, Tasker.Tache.Task
  end

  @doc false
  def changeset(laps, attrs) do
    laps
    |> cast(attrs, [:start, :stop, :task_id])
    |> validate_required([:start, :stop, :task_id])
  end
end
