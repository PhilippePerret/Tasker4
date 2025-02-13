defprotocol TFormat do
  @doc "Convertit une valeur en string formatée"
  def to_s(value, options \\ [])
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