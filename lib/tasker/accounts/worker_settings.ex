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
    field :worktime_settings, :map
    belongs_to :worker, Tasker.Accounts.Worker

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(worker_settings, attrs) do
    attrs = attrs
    |> string_values_to_real_values()

    worker_settings
    |> cast(attrs, [:worker_id, :display_prefs, :interaction_prefs, :task_prefs, :project_prefs, :worktime_settings])
    |> unique_constraint(:worker_id)
    |> validate_required([])
  end

  def string_values_to_real_values(attrs) do
    ["display_prefs", "interaction_prefs", "task_prefs", "project_prefs", "worktime_settings"]
    |> Enum.reduce(attrs, fn prop, attrs ->
      prefs = attrs[prop]
      |> Enum.reduce(attrs[prop], fn {key, svalue}, coll ->
        Map.put(coll, key, StringTo.value(svalue))
      end)
      %{attrs | prop => prefs}
    end)
    |> IO.inspect(label: "Préférences après traitement")
  end
end
