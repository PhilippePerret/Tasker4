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
    changeset = assigns.changeset

    task_time = changeset.data.task_time
    assigns = assigns
    |> assign(:mark_start, define_mark_started_at(task_time.started_at))

    mark_end    = define_mark_ended_at(task_time.ended_at)
    mark_giveup = define_mark_givenup_at(task_time.given_up_at)

    segment_fin =
      if task_time.given_up_at, do: mark_giveup, else: mark_end
    
    execution_time =
      case task_time.execution_time do
      nil -> ""
      extime -> dgettext("tasker", "Execution time") <> " : " <> TFormat.to_duree(extime)
      end
    assigns = assigns |> assign(:exec_time, execution_time)

    ~H"""
    <h3><%= dgettext("tasker", "Task Current Status") %></h3>
    <div>
      {@mark_start}, {segment_fin}.
    </div>
    <div>{@exec_time}</div>
    """
  end


  @doc """
  Composant HEX pour composer le bloc-note de la tâche, mais aussi 
  des autres propriétaires qui peuvent en posséder.
  """
  attr :changeset, Ecto.Changeset, required: true

  def blocnotes(assigns) do
    changeset = assigns.changeset
    task_spec = changeset.data.task_spec
    |> IO.inspect(label: "\nTASK_SPEC")

    ~H"""
    <div id="blocnotes-container">
      <div id="blocnotes-note-list">
        <%= for note <- task_spec.notes do %>
          <div class="task-note">
            <span class="tiny-buttons fright">[edit][remove]</span>
            <div class="title">{note.title}</div>
            <div class="details">{note.details}</div>
          </div>
        <% end %>
      </div>
      <div class="buttons">
        <button class="btn btn-add">＋</button>
      </div>
    </div>
    """
  end



  # ---- Sous-méthodes des composants ---- 

  defp define_mark_givenup_at(nil), do: ""
  defp define_mark_givenup_at(given_up_at) do
    if given_up_at do
      dgettext("tasker", "given up at") <> " " <> TFormat.to_s(given_up_at, time: true)
    else "" end
  end
  defp define_mark_started_at(nil), do: gettext("Not started yet")
  defp define_mark_started_at(started_at) do
    gettext("Started at") <> " " <> TFormat.to_s(started_at, time: true) <> H.ilya(started_at, prefix: " (", suffix: ")")
  end
  defp define_mark_ended_at(nil), do: gettext("thus not finished")
  defp define_mark_ended_at(ended_at) do
    case ended_at do
    nil -> gettext("not finished yet")
    _ -> gettext("ended at") <> " " <> TFormat.to_s(ended_at, time: true)
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
