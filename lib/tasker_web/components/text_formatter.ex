defprotocol TFormat do
  @doc "Convertit une valeur en string formatée"
  def to_s(value, options \\ [])
  @doc "Convertit un valeur en durée humaine"
  def to_duree(value, options \\ [])
end

defimpl TFormat, for: Integer do
  def to_s(value, _options \\ []) do
    Integer.to_string(value)
  end
  @doc """
  Reçoit un entier (nombre de secondes) et retourne une durée 
  formatée

  ## Examples :

      iex> TFormat.to_duree(60)
      ~s(0 h 01)

      iex> TFormat.to_duree(3600)
      ~s(1 h 00)

  """
  def to_duree(value, _options \\ []) do
    case value do
      0 -> "0 h 00"
      _ ->
        hrs = div(value, 60)
        mns = rem(value, hrs)
        mns = (mns < 10) && "0#{mns}" || mns
        "#{hrs} h #{mns}"
    end
  end
end

defimpl TFormat, for: Atom do
  def to_duree(value, _options \\ []) do
    "atom: #{inspect value}"
  end
  def to_s(value, _options \\ []) do
    Atom.to_string(value)
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

  def to_duree(value, options \\ []) do
    TFormat.to_duree(div(DateTime.to_unix(value), 60), options)
  end
end
defimpl TFormat, for: DateTime do
  def to_s(value, options \\ []) do
    format = options[:time] && "%d %m %Y %H:%M" || "%d %m %Y"
    Calendar.strftime(value, format)
  end

  def to_duree(value, options \\ []) do
    TFormat.to_duree(div(DateTime.to_unix(value), 60), options)
  end
end
