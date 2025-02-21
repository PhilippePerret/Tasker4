defmodule Tasker.Accounts.WorkerSettings do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "worker_settings" do
    field :display_prefs, :map
    field :interaction_prefs, :map
    field :task_prefs, :map
    field :project_prefs, :map
    field :divers_prefs, :map
    belongs_to :worker, Tasker.Accounts.Worker

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(worker_settings, attrs) do
    worker_settings
    |> cast(attrs, [:worker_id, :display_prefs, :interaction_prefs, :task_prefs, :project_prefs, :divers_prefs])
    |> unique_constraint(:worker_id)
    |> validate_required([])
  end
end
