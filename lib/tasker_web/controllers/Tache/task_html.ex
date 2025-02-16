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

  @hour   60          # heure   = 60 minutes
  @day    7 * @hour   # journée = 7 heures
  @week   5 * @day    # semaine = 5 jours ouvrés pour 7 heures
  @month  4 * @week   # mois    = 4 semaines ouvrées

  @duree_units [ @month, @week, @day, @hour, 1 ]
  
  def options_duree do
    [
      {dgettext("ilya", "months"), @month},
      {dgettext("ilya", "weeks"), @week},
      {dgettext("ilya", "days"), @day},
      {dgettext("ilya", "hours"), @hour},
      {dgettext("ilya", "minutes"), 1},
    ]
  end

  def options_priority do
    [
      {gettext("not defined"), "nil"}, 
      {gettext("absolute (priority)"), 5}, 
      {gettext("high (priority)"), 4}, 
      {gettext("secondary (priority)"), 3}, 
      {gettext("normal (priority)"), 2}, 
      {gettext("low (priority)"), 1}, 
      {gettext("very low (priority)"), 0}      
    ]
  end
  def options_urgence do
    [
      {gettext("not defined"), "nil"}, 
      {gettext("Critical (urgency)"), 5}, # Très urgente
      {gettext("Urgent (urgency)"), 4},   # Urgente
      {gettext("Time-sensitive (urgency)"), 3},     # Pressée
      {gettext("As soon as possible (urgency)"), 2}, # Dès que possible
      {gettext("Can wait (urgency)"), 1} # Peut attendre
    ]
  end

 
  defp format_expect_duration(nil), do: {nil, "1"}
  defp format_expect_duration(minutes) when is_integer(minutes) do
    Enum.find_value(@duree_units,{1, "1"}, fn unit_val ->
      if rem(minutes, unit_val) == 0 do
        { div(minutes, unit_val), unit_val }
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
    assigns = assigns 
    |> assign(:exec_time, execution_time)
    |> assign(:segment_fin, segment_fin)

    ~H"""
    <h3><%= dgettext("tasker", "Task Current Status") %></h3>
    <div>
      {@mark_start}, {@segment_fin}.
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
    # |> IO.inspect(label: "\nTASK_SPEC")

    assigns = assigns 
    |> assign(all_notes: task_spec.notes)
    |> assign(task_spec: task_spec)

    ~H"""
    <div id="blocnotes-container">
      <div id="blocnotes-note-list">
        <%= for note <- @all_notes do %>
          <div class="task-note">
            <span class="tiny-buttons fright">[edit][remove]</span>
            <div class="title">{note.title}</div>
            <div class="details">{note.details}</div>
          </div>
        <% end %>
      </div>
      <div id="blocnotes-note-form">
        <input type="hidden" value={@task_spec.id} id="new_note_task_spec_id" />
        <div>
          <input type="text" value="" id="new_note_title" style="border:1px solid #999;" class="long" placeholder="Titre de la note" />
        </div>
        <div style="margin-top:12px;">
          <textarea id="new_note_details" placeholder="Détail de la note" style="height:120px;"></textarea>
        </div>
      </div>
      <div class="buttons">
        <button type="button" class="btn btn-add" onclick="Notes.create()">＋</button>
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

end
