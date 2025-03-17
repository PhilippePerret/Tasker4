defmodule Tasker.Tache.TaskTime do
  use Ecto.Schema
  import Ecto.Changeset
  import Crontab.CronExpression

  use Gettext, backend: TaskerWeb.Gettext

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "task_times" do
    field :started_at, :naive_datetime
    field :should_start_at, :naive_datetime
    field :should_end_at, :naive_datetime
    field :imperative_end, :boolean, default: false
    field :ended_at, :naive_datetime
    field :given_up_at, :naive_datetime
    field :recurrence, :string
    field :expect_duration, :integer
    field :execution_time, :integer
    field :deadline_trigger, :boolean, default: true
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
    attrs = attrs
    |> convert_expect_duration()
    |> treate_recurrence_if_any()

    task_time
    |> cast(attrs, [:task_id, :should_start_at, :should_end_at, :imperative_end, :started_at, :ended_at, :given_up_at, :recurrence, :expect_duration, :execution_time, :deadline_trigger])
    |> validate_required([:task_id])
    |> validate_end_at()
    |> validate_should_end_at()
    |> validate_end_or_given_up()
  end

  # --- Méthodes de conversion des attributs (avant validation) ---

  defp convert_expect_duration(%{} = attrs), do: attrs
  defp convert_expect_duration(%{"exp_duree_unite" => edur_unite} = attrs) do
    IO.inspect(attrs, label: "ATTRS in convert_expect_duration")
    if edur_unite == "---" do
      attrs
    else
      edur_value = Map.get(attrs, "exp_duree_value")
      edur_value = String.to_integer(edur_value)
      edur_unite = String.to_integer(edur_unite)
      Map.put(attrs, "expect_duration", edur_value * edur_unite)
    end
  end
  defp convert_expect_duration(attrs), do: attrs

  # Traitement en cas de tâche à récurrence
  # Chaque fois (i.e. à chaque modification de la tâche, même
  # lorsqu'elle ne modifie pas sa récurrence), on regarde si la
  # tâche est récurrente et, le cas échéant, on définit ses temps
  # en fonction du cron
  # 
  # @param {Map} attrs  Les attributs. Note : ils font forcément 
  #                     définis puisque traités avant déjà.
  defp treate_recurrence_if_any(attrs) do
    recurrence = Map.get(attrs, "recurrence")
    if recurrence && recurrence != "" do
      # 
      # Quand c'est une tâche récurrente
      # 
      now = NaiveDateTime.utc_now()
      start_at = Crontab.Scheduler.get_next_run_date!(~e[#{recurrence}], now)
      # Un "DÉLAI DE RÉALISATION" est-il défini ?
      # Rappel : le "délai de réalisation" concerne le laps de temps
      # dans lequel la tâche doit être réalisée, quelle que soit sa
      # durée de réalisation (qui est le temps que prendra la réali-
      # sation de la tâche).
      # Pour une tâche récurrente, pour calculer ce délai de réalisa-
      # tion, on prend le should_end_at et should_start_at actuels,
      # s'ils existent.
      should_start = Map.get(attrs, "should_start_at", nil)
      should_end   = Map.get(attrs, "should_end_at", nil)
      delai_realisation = if should_start && should_end do
        should_start = NaiveDateTime.from_iso8601!("#{should_start}:00")
        should_end   = NaiveDateTime.from_iso8601!("#{should_end}:00")
        NaiveDateTime.diff(should_end, should_start, :minute)
      else nil end
      end_at = if delai_realisation do
        NaiveDateTime.add(start_at, delai_realisation, :minute)
      else nil end
      Map.merge(attrs, %{
        "should_start_at" => start_at,
        "should_end_at"   => end_at
      })
    else # <= Ce n'est pas une tâche récurrente
      attrs
    end
  end

  # --- Méthodes de validations des attributs ---
  
  defp validate_end_or_given_up(changeset) do
    changeset
    |> validate_change(:ended_at, fn :ended_at, ended ->
      given_up = get_field(changeset, :given_up_at)
      if ended && given_up do
        [ended_at: dgettext("tasker", "cannot be set: abandonment date already defined")]
      else [] end
    end)
    |> validate_change(:given_up_at, fn :given_up_at, given_up ->
      ended = get_field(changeset, :ended_at)
      if ended && given_up do
        [given_up_at: dgettext("tasker", "cannot be set: end date already defined")]
      else [] end
    end)
  end
  defp validate_end_at(changeset) do
    changeset
    |> validate_change(:ended_at, fn :ended_at, ended_at ->
      started_at = get_field(changeset, :started_at)
      if started_at && ended_at && NaiveDateTime.compare(ended_at, started_at) == :lt do
        [ended_at: dgettext("tasker", "cannot be before %{started_at}", started_at: TFormat.to_s(started_at))]
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
        [should_end_at: dgettext("tasker", "cannot be before %{should_start_at}", should_start_at: TFormat.to_s(should_start_at))]
      else
        []
      end
    end)
  end



end
