defmodule Tasker.Helper do

  use Gettext, backend: TaskerWeb.Gettext

  @doc """
  Retourne la durée passée depuis la date +date+

  @param date {NaiveDateTime} Date de référence
  @param options {Keyword} Liste d'options
  @param options.prefix {String} À mettre avant le message
  @param options.suffix {String} À mettre après le message
  """
  def ilya(date, options \\ []) do
    diff = NaiveDateTime.diff(NaiveDateTime.utc_now(), date, :minute)
    message =
    cond do
    diff < 1 -> dgettext("ilya", "right now") <> "[#{diff}]"
    true ->
      segs = []
      [segs, reste] = foo_foostr(segs, diff, :week)
      [segs, reste] = foo_foostr(segs, reste, :day)
      [segs, reste] = foo_foostr(segs, reste, :hour)
      [segs, reste] = foo_foostr(segs, reste, :minute)
      duree_humaine = 
      case Enum.count(segs) do
      1 -> Enum.at(0)
      _ -> 
        {autres, dernier} = Enum.split(segs, -1)
        dgettext("ilya", "%{items}, and %{last}", items: Enum.join(autres, ", "), last: dernier)
      end
      dgettext("ilya", "%{duration} ago", duration: duree_humaine)
    end
    "#{options[:prefix]}#{message}#{options[:suffix]}"
  end

  defp foo_foostr(segs, minutes, :week) do
    calcule_ilya_for(segs, minutes, 7 * 24 * 60, dgettext("ilya", "week"))
  end
  defp foo_foostr(segs, minutes, :day) do
    calcule_ilya_for(segs, minutes, 24 * 60, dgettext("ilya", "day"))
  end
  defp foo_foostr(segs, minutes, :hour) do
    calcule_ilya_for(segs, minutes, 60, dgettext("ilya", "hour"))
  end
  defp foo_foostr(segs, minutes, :minute) do
    calcule_ilya_for(segs, minutes, 1, dgettext("ilya", "minute"))
  end

  defp calcule_ilya_for(segs, minutes, diviseur, unite) do
    value = div(minutes, diviseur)
    segs = 
      cond do 
        value > 0 -> 
          unite = "#{unite}#{value == 1 && "" || "s"}"
          segs ++ ["#{value} #{unite}"]
        true -> segs
      end
    reste = rem(minutes, diviseur)
    [segs, reste]
  end

end