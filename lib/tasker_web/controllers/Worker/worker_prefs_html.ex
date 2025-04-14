defmodule TaskerWeb.WorkerPrefsHTML do
  use TaskerWeb, :html

  embed_templates "worker_prefs_html/*"

  def feuille_css(assigns) do
    code_css = File.read!(Path.join([__DIR__,"worker_prefs_html","prefs.css"]))
    assigns = assigns
    |> assign(:code_css, code_css)
    
    ~H"""
    <style type="text/css"><%= raw @code_css %></style>
    """
  end

  # Constantes qui définit toutes les propriétés des réglages, leur
  # type, ce qui permet de les afficher facilement dans les fiches
  # 
  # NOTES
  #   - Si des réglages/préférences sont ajoutés, il faut les ajouter
  #     dans la fonction :default_worker_settings du fichier
  #     tasker/_accounts.ex
  # 
  @settings_specs [
    %{
      rub_id: :display_prefs,
      rub_name: gettext("Display preferences"),
      properties: [
        %{
          id: :theme, name: gettext("Theme"), 
          type: :select, values: [["standard", "standard"]]
        }
      ]
    },
    %{
      rub_id: :interaction_prefs,
      rub_name: gettext("Interaction preferences"),
      properties: [
        %{id: :can_be_joined, name: gettext("Can be contacted"), type: :boolean, not_nil: true},
        %{id: :notification,  name: gettext("Notifications"), type: :boolean, not_nil: true}
      ]
    },
    %{
      rub_id: :task_prefs,
      rub_name: gettext("Task preferences"),
      properties: [
        %{id: :default_task_duration, name: gettext("Task Default duration"), type: :integer, unit: gettext("minutes"), min: 1},
        %{id: :max_tasks_count, name: gettext("Max task count"), type: :integer, min: 10, max: 10_000, info: gettext("Max task count (info)"), unit: nil},
        %{id: :alert_for_exclusive, name: gettext("Alert for exclusive"), type: :boolean, not_nil: true, info: gettext("alert for exclusive (info)")},
        %{id: :time_before_alert, name: gettext("Time before alert"), type: :duration, info: gettext("Time before alert (info)")},
        %{id: :alert_hour, name: gettext("Alert hour"), type: :clock, info: gettext("alert hour (info)")},
        %{id: :filter_on_nature, name: gettext("Filter on nature"), type: :select, values: [[:enabled_same_nature, gettext("Enable same nature")], [:never_same_nature, gettext("Never same nature")], [:avoid_same_nature, gettext("Avoid same nature")]], info: gettext("Filter on nature (info)")},
        %{id: :filter_on_duree, name: gettext("Filter on duration"), type: :select, values: [[false, gettext("false")], [:long, gettext("Long")], [:short, gettext("Short")], [:medium, gettext("Medium")]], info: gettext("Filter on duration (info)")},
        %{id: :prioritize_same_nature, name: gettext("Prioritize same nature"), type: :boolean, not_nil: false, info: gettext("Prioritize same nature (info)")},
        %{id: :sort_by_task_duration, name: gettext("Sort by task duration"), type: :select, values: [["nil", gettext("No")], [:long, gettext("Longest before")], [:short, gettext("Shortest before")]]},
        %{id: :sort_by_task_difficulty, name: gettext("Sort by task difficulty"), type: :select, values: [["nil", gettext("No")], [:easy, gettext("Easiest before")], [:hard, gettext("Hardest before")]]},
        %{id: :custom_natures, name: gettext("Custom natures"), type: :list, info: gettext("Custom natures (info)")},
      ]
      },
      %{
        rub_id: :project_prefs,
        rub_name: gettext("Project preferences"),
        properties: [
          %{id: :folder_always_required, name: gettext("Folder always required"), type: :boolean, not_nil: true},          
      ]
    },
    %{
      rub_id: :worktime_settings,
      rub_name: gettext("Worktime settings"),
      properties: [
        %{id: :work_start_time, name: gettext("Work start time"), type: :clock, info: gettext("Work start time (info)")},
        %{id: :morning_end_time, name: gettext("Morning end time"), type: :clock, info: gettext("Morning end time (info)")},
        %{id: :midday_start_time, name: gettext("Midday start time"), type: :clock, info: gettext("Midday start time (info)")},
        %{id: :work_end_time, name: gettext("Work end time"), type: :clock, info: gettext("Work end time (info)")},
        %{id: :near_future, name: gettext("Near future days"), type: :integer, unit: dgettext("ilya", "days"), min: 2, max: 1000, info: gettext("Near future days (info)")}
      ]
    }
  ]


  def affichage_settings(settings, mode \\ :display) do
    # IO.inspect(settings, label: "Setting pour affichage/édition")
    @settings_specs
    |> Enum.map(fn dmap ->
      values_map = Map.get(settings, dmap.rub_id)
      # |> IO.inspect(label: "\nvalues map")
      properties = 
        dmap.properties 
        |> Enum.map(fn dprop ->
          value = Map.get(values_map, Atom.to_string(dprop.id))
          # |> IO.inspect(label: "value de prop #{dprop.id}")

          explication = if Map.get(dprop, :info) do
            ~s(<div class="info">#{dprop.info}</div>)
          else "" end

          dprop = Map.put(dprop, :rub_id, dmap.rub_id)
          ~s(<div class="property">) <>
          ~s(<label>#{dprop.name}</label>) <>
          ~s(<span class="value">#{formate_field(dprop, value, mode)}</span>) <>
          explication <>
          ~s(</div>)
        end)
        |> Enum.join("")

      """
      <h3>#{dmap.rub_name}</h3>
      <div class="properties">
      #{properties}
      </div>
      """
    end)
    |> Enum.join("")
  end

  def formate_field(%{type: :boolean} = data, value, :edit) do
    fields = [
      ["true", gettext("true")],
      ["false", gettext("false")]
    ]
    fields =
    if data.not_nil do fields else
      fields ++ [["nil", gettext("not defined")]]
    end
    options = formate_options(fields, value)
    """
    <select id="#{data.id}-field"name="#{data.rub_id}[#{data.id}]">#{options}</select>
    """
  end
  def formate_field(%{type: :boolean} = _data, value, :display) do
    string = "#{value}"
    Gettext.gettext(TaskerWeb.Gettext, string)
  end
  
  def formate_field(%{type: :clock} = data, value, mode) do
    case mode do
    :edit ->
      """
      <input type="time" id="#{data.id}-field" name="#{data.rub_id}[#{data.id}]" value="#{value}" />
      """
    :display ->
      "#{value}"
    end
  end
  def formate_field(%{type: :select} = data, value, mode) do
    case mode do
    :edit ->
      options = formate_options(data.values, value)
      """
      <select id="#{data.id}-field" name="#{data.rub_id}[#{data.id}]">#{options}</select>
      """
    :display ->
      ditem =
      data.values 
      |> Enum.filter(fn [val, title] -> 
        IO.puts "value:#{inspect ~s(#{value||"nil"})} / val:#{inspect ~s(#{val})}"
        ~s(#{value||"nil"}) == ~s(#{val})
      end) 
      |> Enum.at(0) 
      [_value, title] = ditem || [nil, gettext("unfound")]
      "#{title}"
    end
  end

  def formate_field(%{type: :integer} = data, value, mode) do
    case mode do
    :edit ->
      """
      <input id="#{data.id}-field" name="#{data.rub_id}[#{data.id}]" type="number" value="#{value}" max="#{Map.get(data, :max)}" min="#{Map.get(data, :min)}" style="text-align:right;" />
      <span class="unit">#{data.unit}</span>
      """
    :display ->
      """
      #{value}<span class="unit">#{data.unit}</span>
      """
    end
  end

  def formate_field(%{type: :duration} = data, value, :edit) do
    # Dans ce type, la valeur doit être définie par [quantity, :unit]
    value = cond do
      is_binary(value) and String.starts_with?(value, "[") and String.ends_with?(value, "]") ->
        StringTo.list(value)
      is_list(value) -> value
      true -> [1, "minute"] 
    end
    options = [
      ["minute" , gettext("minutes")],
      ["hour"   , gettext("hours")],
      ["day"    , gettext("days")],
      ["week"   , gettext("weeks")],
      ["month"  , gettext("months")],
      ["year"   , gettext("years")]
    ] |> formate_options(Enum.at(value, 1))

    quant = Enum.at(value, 0)
    quant = cond do
    is_binary(quant) -> String.to_integer(quant)
    true -> quant
    end

    """
    <input id="#{data.id}-field" name="#{data.rub_id}[#{data.id}]" type="hidden" value="#{Jason.encode!(value)}" />
    <input id="#{data.id}-quantity-field" onchange="gere#{data.id}()" type="number" value="#{quant}" max="#{Map.get(data, :max)}" min="#{Map.get(data, :min)}" style="text-align:right;" />
    <select id="#{data.id}-unit-field" onchange="gere#{data.id}()">#{options}</select>
    <script type="text/javascript">
    function gere#{data.id}(){
    const value = JSON.stringify([DGet('input##{data.id}-quantity-field').value, DGet('select##{data.id}-unit-field').value])
    DGet('input##{data.id}-field').value = value;
    console.log("Champ #{data.id} mis à ", value)
    }
    </script>
    """
  end
  def formate_field(%{type: :duration} = _data, value, :display) do
    value = StringTo.list(value)
    unit  = Enum.at(value, 1)
    value = Enum.at(value, 0)
    string = "#{unit}s"
    unit = Gettext.gettext(TaskerWeb.Gettext, string)
    """
    #{value}<span class="unit">#{unit}</span>
    """
  end

  def formate_field(%{type: :list} = data, value, mode) do
    value = StringTo.list(value)
    
    case mode do
    :edit ->
      """
      <input id="#{data.id}-field" name="#{data.rub_id}[#{data.id}]" type="text" value="#{Enum.join(value, ", ")}" style="width:500px;" placeholder="item 1, item 2,… item N" />
      """
    :display -> 
      if value == [] do 
        "(#{gettext("empty")})" 
      else 
        Enum.join(value, ", ")
      end
    end
  end

  def formate_field(_data, value, _mode) do
    "AUTRE CHAMP DE VALEUR #{value}"
  end

  def formate_options(values, def_value) do
    values |> 
    Enum.map(fn [value, title] ->
      selected = if value === def_value do ~s( selected="SELECTED") else "" end
      ~s(<option value="#{value}"#{selected}>#{title}</option>)
    end) |> Enum.join("")
  end
end