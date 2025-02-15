defmodule TaskerWeb.TaskHTML do
  use TaskerWeb, :html

  alias Tasker.Helper, as: H

  embed_templates "task_html/*"

  @doc """
  Renders a task form.
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true
  attr :projects, :list, required: true

  def task_form(assigns)

  @duree_units [
    {"43200", 43200},  # Mois
    {"10080", 10080},  # Semaines
    {"1440", 1440},    # Jours
    {"60", 60},        # Heures
    {"1", 1}           # Minutes
  ]
  @duree_unit_name [
    {"mois", 43200},
    {"sems", 10080},
    {"jrs", 1440},
    {"hrs", 60},
    {"mns", 1},
  ]
  
  def options_duree, do: @duree_unit_name
 
  defp format_expect_duration(nil), do: {nil, "1"}
  defp format_expect_duration(minutes) when is_integer(minutes) do
    units = [
      {"43200", 43200},  # Mois
      {"10080", 10080},  # Semaines
      {"1440", 1440},    # Jours
      {"60", 60},        # Heures
      {"1", 1}           # Minutes (fallback)
    ]
  
    Enum.find_value(units, {minutes, "1"}, fn {unit_str, unit_val} ->
      if rem(minutes, unit_val) == 0 do
        {div(minutes, unit_val), unit_str}
      else
        nil
      end
    end)
  end

  @doc """
  Composant pour créer la section qui indique les informations fixes, 
  c'est-à-dire la date de début si elle est définie, la date de fin,
  le temps d'exécution, etc. donc les informations qu'on ne peut pas
  modifier dans le formulaire de tâche.
  """
  attr :changeset, Ecto.Changeset, required: true

  def current_state(assigns) do
    faux_depart = 
      NaiveDateTime.utc_now()
      |> NaiveDateTime.add(-123 * 60)
    task_time = @changeset[:task_time] || %{started_at: faux_depart, ended_at: nil, execution_time: 1000}

    assigns = assigns
    |> assign(:mark_start, define_mark_started_at(task_time))

    mark_end    = define_mark_ended_at(task_time)
    mark_giveup = define_mark_givenup_at(task_time)

    segment_fin =
      if task_time[:given_up_at], do: mark_giveup, else: mark_end
    
    execution_time =
      case task_time[:execution_time] do
      nil -> ""
      extime -> dgettext("tasker", "Execution time") <> " : " <> TFormat.to_duree(extime)
      end

    ~H"""
    <h3><%= dgettext("tasker", "Task Current Status") %></h3>
    <div>
      {@mark_start}, {segment_fin}.
    </div>
    <div>{execution_time}</div>
    """
  end


  @doc """
  Composant HEX pour composer le bloc-note de la tâche, mais aussi 
  des autres propriétaires qui peuvent en posséder.
  """
  attr :changeset, Ecto.Changeset, required: true

  def blocnotes(assigns) do
    ~H"""
    [Bloc-note]
    """
  end



  # ---- Sous-méthodes des composants ---- 

  defp define_mark_givenup_at(nil), do: ""
  defp define_mark_givenup_at(task_time) do
    if task_time[:given_up_at] do
      dgettext("tasker", "given up at") <> " " <> TFormat.to_s(task_time.given_up_at, time: true)
    else "" end
  end
  defp define_mark_started_at(nil), do: gettext("Not started yet")
  defp define_mark_started_at(task_time) when is_map(task_time) do
    gettext("Started at") <> " " <> TFormat.to_s(task_time.started_at, time: true) <> H.ilya(task_time.started_at, prefix: " (", suffix: ")")
  end
  defp define_mark_ended_at(nil), do: gettext("thus not finished")
  defp define_mark_ended_at(task_time) when is_map(task_time) do
    case task_time.ended_at do
    nil -> gettext("not finished yet")
    _ -> gettext("ended at") <> " " <> TFormat.to_s(task_time.ended_at, time: true)
    end
  end

  # def current_state(assigns) do
  #   task_time = @changeset[:task_time] || %{started_at: nil, ended_at: nil}

  #   assigns = assigns
  #   |> assign(:mark_start, task_time.started_at && dgettext("tasker", "Started at") <> task_time.started_at)
  #   |> assign(:mark_end,   task_time.ended_at && dgettext("tasker", "ended at") <> task_time.ended_at)

  #   ~H"""
  #   <h3><%= dgettext("tasker", "Current State") %></h3>
  #   [Construire ici l'état courant.]
  #   #{task_time.started_at && @mark_start)}, #{task_time.ended_at && @mark_end}

  #   """
  # end

end
