defprotocol TFormat do
  @doc "Convertit une valeur en string formatée"
  def to_s(value, options \\ [])
  @doc "Convertit un valeur en durée humaine"
  def to_duree(value, options \\ [])
end

defimpl TFormat, for: Integer do
  def to_duree(value, options \\ []) do
    case value do
      0 -> "0 mns"
      _ ->
        hrs = div(value, 60)
        mns = rem(value, hrs)
        "#{hrs} h #{mns} m"
    end
  end
end

defimpl TFormat, for: Atom do
  def to_duree(value, options \\ []) do
    "atom: #{inspect value}"
  end
end

defimpl TFormat, for: NaiveDateTime do
  # def to_s(value) do
  #   Calendar.strftime(value, "%d %m %Y %H:%M")
  # end
  def to_s(value, options \\ []) do
    format = options[:time] && "%d %m %Y %H:%M" || "%d %m %Y"
    Calendar.strftime(value, format)
  end
end
defimpl TFormat, for: DateTime do
  def to_s(value, options \\ []) do
    format = options[:time] && "%d %m %Y %H:%M" || "%d %m %Y"
    Calendar.strftime(value, format)
  end
end