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
  attr :lang, :string, required: true
  attr :data, :map, required: true

  def task_form(assigns)

  attr :changeset, Ecto.Changeset, required: true
  def bloc_task_scripts(assigns)

  @hour   60          # heure   = 60 minutes
  @day    7 * @hour   # journée = 7 heures
  @week   5 * @day    # semaine = 5 jours ouvrés pour 7 heures
  @month  4 * @week   # mois    = 4 semaines ouvrées

  @duree_units [ @month, @week, @day, @hour, 1 ]
  
  def options_duree do
    [
      {"---", "---"},
      {dgettext("ilya", "months"), @month},
      {dgettext("ilya", "weeks"), @week},
      {dgettext("ilya", "days"), @day},
      {dgettext("ilya", "hours"), @hour},
      {dgettext("ilya", "minutes"), 1},
    ]
  end

  def options_priority do
    [
      {"---", "nil"}, 
      {gettext("exclusive (priority)"), 5}, 
      {gettext("high (priority)"), 4}, 
      {gettext("secondary (priority)"), 3}, 
      {gettext("normal (priority)"), 2}, 
      {gettext("low (priority)"), 1}, 
      {gettext("very low (priority)"), 0}      
    ]
  end
  def options_urgence do
    [
      {"---", "nil"}, 
      {gettext("Critical (urgency)"), 5}, # Très urgente
      {gettext("Urgent (urgency)"), 4},   # Urgente
      {gettext("Time-sensitive (urgency)"), 3},     # Pressée
      {gettext("As soon as possible (urgency)"), 2}, # Dès que possible
      {gettext("Can wait (urgency)"), 1} # Peut attendre
    ]
  end

 
  @doc """
  Composant HEX pour la liste des natures
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :natures, :map, required: true
  attr :lang, :string, required: true

  def bloc_natures(assigns) do
    assigns = assigns
    |> assign(:title, dgettext("natures", "Natures"))
    |> assign(:options_natures, options_natures(assigns.natures))
    |> assign(:explication, dgettext("tasker", "Hold Meta Key to select multiple values."))
    |> assign(:natures_choosed, assigns.changeset.data.natures||[])
    |> assign(:bouton_choose, dgettext("tasker", "Choose task natures"))

    ~H"""
    <div id="natures-container" class="block" style="position:relative;">
      <input id="natures-value" type="hidden" name="task[natures]" value={@natures_choosed} />
      <label onclick="Task.toggleMenuNatures()">{@title}</label>
      <div id="natures-list" onclick="Task.toggleMenuNatures()">[{@bouton_choose}]</div>
      <div id="natures-select-container" class="hidden shadowed" style="position:absolute;top:1em;left:0;z-index:500;">
        <select 
          id="task-natures-select" 
          size="10"
          onchange="Task.onChangeNatures(this)" multiple>
          {raw @options_natures}
        </select>
        <div class="buttons">
          <button type="button" onclick="Task.onCloseMenuNatures()">OK</button>
        </div>
        <div class="explication">{@explication}</div>
      </div>
    </div>
    """
  end
  defp options_natures(map_natures) do
    map_natures
    |> Enum.map(fn {key, value} ->
      ~s(<option value="#{key}">#{Gettext.dgettext(TaskerWeb.Gettext, "natures", value)}</option>)
    end)
    |> Enum.join("")
    # |> IO.inspect(label: "Les menus")
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
      <button type="submit" class="soft" onclick="return Task.beforeSave.call(Task)">{@bouton_name}</button>
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

    has_no_state = is_nil(task_time.started_at) \
                    and is_nil(task_time.ended_at) \
                    and is_nil(task_time.given_up_at) \
                    and is_nil(task_time.execution_time)

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
    |> assign(:visibility, has_no_state && "hidden" || "")

    ~H"""
    <div id="task-current-status-container" class={@visibility}>
      <h3><%= dgettext("tasker", "Task Current Status") %></h3>
      <div>
        {@mark_start}, {@segment_fin}.
      </div>
      <div>{@exec_time}</div>
    </div>
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
      <input type="hidden" id="blocnotes-notes" value={@all_notes} />
      <div id="blocnotes-note-list">
      </div>
      <div id="blocnotes-note-form">
        <input type="hidden" value={@task_spec.id} id="edit_note-task_spec_id" />
        <input type="hidden" id="edit_note-id" />
        <div>
          <input type="text" value="" id="edit_note-title" style="border:1px solid #999;" class="long" placeholder="Titre de la note" />
        </div>
        <div style="margin-top:12px;">
          <textarea id="edit_note-details" placeholder="Détail de la note" style="height:120px;"></textarea>
        </div>
        <div class="buttons">
          <button type="button" class="soft btn-save">{@bouton_save_name}</button>
        </div>
      </div>
    </div>
    """
  end


  # @laps [
  #   {"minute", 1},
  #   {"hour", 60},
  #   {"day",  24 * 60},
  #   {"week", 7 * 24 * 60},
  #   {"month", 30 * 24 * 60},
  #   {"year",  365 * 24 * 60}
  # ]
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
      {dgettext("ilya", "Monday"), 1},
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
      # {dgettext("ilya", "minute") , "minute"}, # Non, il ne la faut pas et si ça arrive, il faut se poser des questions
      {dgettext("ilya", "hour")   , "hour"}, 
      {dgettext("ilya", "day")    , "day"}, 
      {dgettext("ilya", "week")   , "week"}, 
      {dgettext("ilya", "month")  , "month"}, 
      {dgettext("ilya", "year")   , "year"}
    ]
  end

  attr :changeset, Ecto.Changeset, required: true
  attr :expected_duration, :integer, required: true

  def duration_field(assigns) do
    {duree_value, duree_unit} = format_expect_duration(assigns.expected_duration)
    assigns = assigns
    |> assign(:duration_title, gettext("Expected duration"))
    |> assign(:duree_value, duree_value)
    |> assign(:duree_unit, duree_unit)

    ~H"""
    <div>
      <label>{@duration_title}</label>
      <input id="task_time_exp_duree_value" type="number" min="1" max="100" name="task[task_time][exp_duree_value]" class="small-number right" value={@duree_value} />
      <select id="task_time_exp_duree_unit" name="task[task_time][exp_duree_unite]" value={@duree_unit}>
        <%= for {titre, valeur} <- options_duree() do %>
          <% 
            attribs = %{value: valeur}
            attribs = if valeur == @duree_unit do
              Map.merge(attribs, %{selected: "SELECTED"})
            else attribs end
          %>
          <option {attribs}><%= titre %></option>
        <% end %>
      </select>
    </div>
    """
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
  Construit un champ de formulaire pour la récurrence et le renvoie
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :lang, :string, required: true

  def recurrence_form(assigns) do

    # Les assignations pour ce composant
    assigns = assigns 
    |> assign(:recurrence, assigns.changeset.data.task_time.recurrence)
    |> assign(:month_data, month_data())
    |> assign(:data_week, data_week())
    |> assign(:every, gettext("Every"))
    |> assign(:data_repeat_unit, data_repeat_unit())
    |> assign(:at_minute, dgettext("ilya", "at minute"))

    ~H"""
    <input id="task-recurrence" type="hidden" name="task[task_time][recurrence]" value={@recurrence}/>
    <input 
      type="checkbox" 
      onchange="Repeat.onChange(this)" 
      style="display:inline-block;margin-right:1em;vertical-align:bottom;transform:scale(1.8);" 
    /><div id="recurrence-container" class="repeat-container hidden">
      
    
    <div id="repeat-summary" class="small mgb-1"></div>

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
                    <%= for hour <- (23..0//-1) do %>
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
      <div class="right">
        <div id="crontab-shower" style="background-color:#a3d7f1;display:inline-block;border-radius:12px;padding:2px 1em;"></div>
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

  @doc """
  Construction du bloc des tâches autour (avant ou après)
  """
  attr :changeset, Ecto.Changeset, required: true

  def bloc_task_around(assigns) do
    dependencies = assigns.changeset.data.dependencies
    # |> IO.inspect(label: "\nDÉPENDANCES DANS bloc_task_around")
    assigns = assigns
    |> assign(:dependencies, Jason.encode!(dependencies))
    |> assign(:task_before_title, dgettext("tasker", "Previous Tasks"))
    |> assign(:task_after_title, dgettext("tasker", "Next Tasks"))
    |> assign(:title, dgettext("tasker", "Task flow"))
    |> assign(:msg_previous_tasks, text_for_previous_tasks())
    |> assign(:msg_next_tasks, text_for_next_tasks())

    ~H"""
    <h3>{@title}</h3>
    <input type="hidden" id="data-dependencies" value={@dependencies} />
    <div id="previous-tasks-container">
      <button id="btn-choose-previous-tasks" style="width:220px;" type="button">{@task_before_title}</button>
      <div id="previous-task-list" class="task-list"></div>
      <div class="tiny">{@msg_previous_tasks}</div>
    </div>
    <div id="next-tasks-container">
      <button id="btn-choose-next-tasks" style="width:220px;" type="button">{@task_after_title}</button>
      <div id="next-task-list" class="task-list"></div>
      <div class="tiny">{@msg_next_tasks}</div>
    </div>
    """
  end

  defp text_for_previous_tasks do
    dgettext("tasker", "The edited task can only be executed after the completion of all the tasks above.")
  end
  defp text_for_next_tasks do
    dgettext("tasker", "All the tasks above can only be executed after the execution of this task.")
  end
end
