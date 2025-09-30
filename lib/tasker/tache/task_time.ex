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
    field :alert_at, :naive_datetime
    field :alerts, {:array, :map}, default: nil
    field :given_up_at, :naive_datetime
    field :recurrence, :string
    field :expect_duration, :integer
    field :execution_time, :integer
    field :deadline_trigger, :boolean, default: true
    belongs_to :task, Tasker.Tache.Task

    timestamps(type: :utc_datetime)
  end

  # TODO
  # 
  @doc false
  def changeset(task_time, attrs) do
    attrs = attrs
    |> convert_expect_duration()
    |> treate_alerts()
    |> treate_recurrence_if_any()

    task_time
    |> cast(attrs, [:task_id, :should_start_at, :should_end_at, :imperative_end, :started_at, :alert_at, :alerts, :ended_at, :given_up_at, :recurrence, :expect_duration, :execution_time, :deadline_trigger])
    |> validate_required([:task_id])
    |> validate_end_at()
    |> validate_should_end_at()
    |> validate_end_or_given_up()
  end

  # --- Méthodes de conversion des attributs (avant validation) ---

  # Cette méthode gère les alertes.
  # 
  # Les alertes sont gérées à l'aide du champ naive date :alert_at
  # qui définit la prochaine alerte qui sera donnée pour la tâche et
  # le champs :alerts qui contient toutes les alertes de la tâche.
  # :alerts est une table JSON, qui définit {:at, :unity, :quantity}
  # où :
  #   :at     Est la date réelle en fonction de :unity et :quantity
  #   :unity  et :quantity définissent par exemple "2 heures avant"
  #   (quantity: 2, unity: 'hour')
  # 
  defp treate_alerts(%{"alerts" => alerts, "should_start_at" => should_start_at} = attrs) when is_binary(alerts) do
    IO.inspect(alerts, label: "\n\n+++ alerts dans treate_alerts")
    alerts = if is_nil(alerts) do alerts else
      Jason.decode!(alerts)
      |> IO.inspect(label: "\nAlerts décodé")
    end
    cond do
    is_nil(alerts) -> attrs
    Enum.count(alerts) == 0 -> attrs
    true -> 
      # Si la date de démarrage de la tâche est passée, on peut supprimer toute
      # alerte.
      should_start_at = NaiveDateTime.from_iso8601!("#{should_start_at}:00")

      if NaiveDateTime.before?(should_start_at, NaiveDateTime.utc_now()) do
        Map.merge(attrs, %{"alerts" => nil, "alert_at" => nil})
      else
        # alert_at = NaiveDateTime.from_iso8601!("#{Enum.at(alerts, 0) |> Map.get("at")}:00")
        # IO.inspect(alert_at, label: "\nalert_at calculé")
        alert_at = Enum.at(alerts, 0) |> Map.get("at")
        Map.merge(attrs, %{
          "alerts"    => alerts, 
          "alert_at"  => alert_at
        })
      end
      |> IO.inspect(label: "\nattrs rectifiés")
    end
  end
  defp treate_alerts(attrs), do: attrs

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
  def treate_recurrence_if_any(attrs) do
    attrs = XTra.Map.to_binary_keys(attrs)
    recurrence = Map.get(attrs, "recurrence")
    if recurrence && recurrence != "" do
      # 
      # Quand c'est une tâche récurrente
      # 
      now = NaiveDateTime.utc_now()
      now = NaiveDateTime.add(now, 2, :hour) # WARNING (SERA FAUX DANS LES AUTRES PAYS)
      start_at = Crontab.Scheduler.get_next_run_date!(~e[#{recurrence}], now)
      should_start  = Map.get(attrs, "should_start_at", nil)

      start_at =
        if start_at == should_start && attrs["force_next"] do
          # On passe par ici lorsque l'utilisateur marque finie une
          # tâche récurrente, mais avant que son départ ait été
          # atteint. Par exemple, la tâche doit être effectuée au-
          # jourd'hui à 10:00 et il est 9:30. Dans ce cas, quand il
          # marque la tâche récurrente effectuée, le controlleur 
          # ajoute "force_next" aux données envoyées. Si le prochain
          # temps est le même que le start-at courant, cette condi-
          # tion force l'utilisation du prochain temps.
          Crontab.Scheduler.get_next_run_date!(~e[#{recurrence}], NaiveDateTime.add(start_at, 1, :hour))
        else
          start_at
        end
      # Un "DÉLAI DE RÉALISATION" est-il défini ?
      # Rappel : le "délai de réalisation" concerne le laps de temps
      # dans lequel la tâche doit être réalisée, quelle que soit sa
      # durée de réalisation (qui est le temps que prendra la réali-
      # sation de la tâche).
      # Pour une tâche récurrente, pour calculer ce délai de réalisa-
      # tion, on prend le should_end_at et should_start_at actuels,
      # s'ils existent.
      should_end    = Map.get(attrs, "should_end_at", nil)
      duration      = Map.get(attrs, "expect_duration", nil)
      delai_realisation = 
        cond do
          should_start && should_end -> 
            should_start = if String.length(should_start) == String.length("2025-10-10T10:00") do
              should_start <> ":00"
            else
              should_start
            end
            should_end = if String.length(should_end) == String.length("2025-10-10T10:00") do
              should_end <> ":00"
            else
              should_end
            end
            should_start = NaiveDateTime.from_iso8601!("#{should_start}")
            should_end   = NaiveDateTime.from_iso8601!("#{should_end}")
            NaiveDateTime.diff(should_end, should_start, :minute)
          should_start && duration ->
            duration
          true -> 
            nil
          end
      end_at = 
        if delai_realisation do
          NaiveDateTime.add(start_at, delai_realisation, :minute)
        else 
          nil 
        end
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
