defmodule Tasker.Tache.TaskTime do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "task_times" do
    field :priority, :integer
    field :started_at, :naive_datetime
    field :should_start_at, :naive_datetime
    field :should_end_at, :naive_datetime
    field :ended_at, :naive_datetime
    field :given_up_at, :naive_datetime
    field :urgence, :integer
    field :recurrence, :string
    field :expect_duration, :integer
    field :execution_time, :integer
    belongs_to :task, Tasker.Tache.Task

    timestamps(type: :utc_datetime)
  end

  # TODO
  #   * inventer started_at lorsque ended_at ou given_up_at est
  #     fourni mais que le départ n'a pas été fixé. Le rechercher
  #     dans les executions.
  # 
  @doc false
  def changeset(task_time, attrs) do
    task_time
    |> cast(attrs, [:task_id, :should_start_at, :should_end_at, :started_at, :ended_at, :given_up_at, :priority, :urgence, :recurrence, :expect_duration, :execution_time])
    |> validate_required([:task_id])
    |> validate_end_at()
    |> validate_should_end_at()
    |> validate_end_or_given_up()
  end

  defp validate_end_or_given_up(changeset) do
    changeset
    |> validate_change(:ended_at, fn :ended_at, ended ->
      given_up = get_field(changeset, :given_up_at)
      if ended && given_up do
        [ended_at: "cannot be set: abandonment date already defined"]
      else [] end
    end)
    |> validate_change(:given_up_at, fn :given_up_at, given_up ->
      ended = get_field(changeset, :ended_at)
      if ended && given_up do
        [given_up_at: "cannot be set: end date already defined"]
      else [] end
    end)
  end
  defp validate_end_at(changeset) do
    changeset
    |> validate_change(:ended_at, fn :ended_at, ended_at ->
      started_at = get_field(changeset, :started_at)
      if started_at && ended_at && NaiveDateTime.compare(ended_at, started_at) == :lt do
        [ended_at: "cannot be before started_at"]
      else
        []
      end
    end)
  end

  defp validate_should_end_at(changeset) do
    changeset
    |> validate_change(:should_end_at, fn :should_end_at, should_end_at ->
      should_start_at = get_field(changeset, :should_start_at)
      if should_start_at && should_end_at && NaiveDateTime.compare(should_end_at, should_start_at) == :lt do
        [should_end_at: "cannot be before should_start_at"]
      else
        []
      end
    end)
  end



end
