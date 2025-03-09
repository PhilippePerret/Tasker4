defmodule Tasker.ToolBox.TaskScript do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "task_scripts" do
    field :title, :string
    field :type, :string
    field :argument, :string
    belongs_to :task, Tasker.Tache.Task
  end

  @doc false
  def changeset(task_script, attrs) do
    task_script
    |> cast(attrs, [:title, :type, :argument, :task_id])
    |> validate_required([:title, :type, :task_id])
  end
end
