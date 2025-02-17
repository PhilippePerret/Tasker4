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
  Composant du bouton pour sauver la tâche, qu'on trouve à plusieurs
  endroits du formulaire
  """
  def bouton_save_tache(assigns) do
    assigns = assigns
    |> assign(:bouton_name, dgettext("tasker", "Save Task"))
    ~H"""
    <div class="buttons">
      <button type="submit" class="soft" onclick="return Task.beforeSave()">{@bouton_name}</button>
    </div>

    """
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
    |> assign(bouton_save_name: dgettext("tasker", "Save this note"))

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
        <button type="button" class="soft btn-add" onclick="Notes.create()">{@bouton_save_name}</button>
      </div>
    </div>
    """
  end


  @laps [
    {"minute", 1},
    {"hour", 60},
    {"day",  24 * 60},
    {"week", 7 * 24 * 60},
    {"month", 30 * 24 * 60},
    {"year",  365 * 24 * 60}
  ]
  def month_data do
    [
      {dgettext("ilya","January"), 1}, 
      {dgettext("ilya","February"), 2}, 
      {dgettext("ilya","March"), 3}, 
      {dgettext("ilya","April"), 4}, 
      {dgettext("ilya","May"), 5}, 
      {dgettext("ilya","June"), 6}, 
      {dgettext("ilya","July"), 7}, 
      {dgettext("ilya","August"), 8}, 
      {dgettext("ilya","Septembre"), 9}, 
      {dgettext("ilya","October"), 10}, 
      {dgettext("ilya","November"), 11}, 
      {dgettext("ilya","December"), 12}
    ]
  end

  def data_week do 
    [
      {dgettext("ilya", "Sunday"), 1},
      {dgettext("ilya", "Tuesday"), 2},
      {dgettext("ilya", "Wednesday"), 3},
      {dgettext("ilya", "Thursday"), 4},
      {dgettext("ilya", "Friday"), 5},
      {dgettext("ilya", "Saturday"), 6},
      {dgettext("ilya", "Sunday"), 0}
    ]
  end

  def data_repeat_unit do
    [
      {dgettext("ilya", "minute") , "minute"}, 
      {dgettext("ilya", "hour")   , "hour"}, 
      {dgettext("ilya", "day")    , "day"}, 
      {dgettext("ilya", "week")   , "week"}, 
      {dgettext("ilya", "month")  , "month"}, 
      {dgettext("ilya", "year")   , "year"}
    ]
  end


  @doc """
  Construit un champ de formulaire pour la récurrence et le renvoie
  """
  attr :changeset, Ecto.Changeset, required: true

  def recurrence_form(assigns) do
    assigns = assigns 
    |> assign(:recurrence, assigns.changeset.data.task_time.recurrence)
    |> assign(:month_data, month_data())
    |> assign(:data_week, data_week())
    # TODO : PLUTÔT PASSER TOUT ÇA PAR UN JSON
    |> assign(:every, gettext("Every"))
    |> assign(:every_min, gettext("every"))
    |> assign(:on_for_day, gettext("on (day)"))
    |> assign(:monday, dgettext("ilya", "monday"))
    |> assign(:tuesday, dgettext("ilya", "tuesday"))
    |> assign(:wednesday, dgettext("ilya", "wednesday"))
    |> assign(:thursday, dgettext("ilya", "thursday"))
    |> assign(:friday, dgettext("ilya", "friday"))
    |> assign(:saturday, dgettext("ilya", "saturday"))
    |> assign(:sunday, dgettext("ilya", "sunday"))
    |> assign(:repeat_this_task, gettext("Repeat this task"))
    |> assign(:data_repeat_unit, data_repeat_unit())
    |> assign(:at_minute, dgettext("ilya", "at minute"))

    ~H"""
    <script type="text/javascript">
    /* Pour mettre les éléments de langue */
    const LANG = {
        Repeat_this_task: "<%= @repeat_this_task %>"
      , every: "<%= @every_min %>"
      , on_for_day: "<%= @on_for_day %>"
      , days: {0: "<%= @sunday %>", 1: "<%= @monday %>", 2: "<%= @tuesday %>", 3: "<%= @wednesday %>", 4: "<%= @thursday %>", 5: "<%= @friday %>", 6: "<%= @saturday %>"}
    };
    </script>
    <input id="task-recurrence" type="hidden" name="task[task_time][recurrence]" value={@recurrence}/>
    <input 
      type="checkbox" 
      onchange="Repeat.onChange(this)" 
      style="display:inline-block;margin-right:1em;vertical-align:bottom;transform:scale(1.8);" 
    /><div id="recurrence-container" class="repeat-container hidden">
      <div id="repeat-summary"></div>
      <div class="repeat-form inline-fields">
      <div class="inline-fields" style="vertical-align:bottom;">
          <label class="no-points">{@every}</label>
          <input type="number" name="frequency-value" class="small-number" value={1} />
          <select class="repeat-frequency-unit" name="frequency-unit">
            <%= for {lap_title, lap_value} <- @data_repeat_unit do %>
              <script type="text/javascript">
                LANG.<%= lap_value %> = "<%= lap_title %>";
              </script>
              <option value={lap_value}><%= lap_title %></option>
            <% end %>
          </select>
        </div>
        <div class="inline-fields">
          <span class="repeat-property at-minute"> 
                <label class="no-points">{@at_minute}</label>
                <select class="repeat-at-minute" name="at-minute">
                  <option value="---">---</option>
                  <%= for minute <- (0..59//5) do %>
                    <option value={minute}><%= minute %></option>
                  <% end %>
                </select>
          </span>

          <span class="repeat-property at-hour"> 
                  <label class="no-points">de l'heure</label>
                  <select class="repeat-at-hour" name="at-hour">
                    <option value="---">---</option>
                    <option value="all">toutes</option>
                    <%= for hour <- (23..0) do %>
                      <option value={hour}><%= hour %></option>
                    <% end %>
                  </select>
          </span>
        </div>

        <div class="inline-fields">
          <span class="repeat-property at-day"> 
                  <label class="no-points">le </label>
                  <select class="repeat-at-day" name="at-day">
                    <option value="---">---</option>
                    <%= for {titre, valeur} <- @data_week do %>
                      <option value={valeur}><%= titre %></option>
                    <% end %>
                  </select>
          </span>
        </div>

        <div class="inline-fields">
          <span class="repeat-property at-mday"> 
                  <label class="no-points">le </label>
                  <select class="repeat-at-mday" name="at-mday">
                    <option value="---">---</option>
                    <%= for mday <- (1..31) do %>
                      <option value={mday}><%= mday %></option>
                    <% end %>
                  </select>
          </span>
          <span class="repeat-property at-month">
                  <label class="no-points"> du mois de</label>
                  <select class="repeat-at-month" name="at-month">
                    <option value="---">---</option>
                    <%= for {title, value} <- @month_data do %>
                      <option value={value}><%= title %></option>
                    <% end %>
                  </select>
          </span>
        </div>


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
