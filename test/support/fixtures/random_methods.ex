defmodule Random.RandMethods do

  @lorem_words ~w(Lorem ipsum dolor sit amet consectetur adipiscing elit sed do eiusmod tempor incididunt ut labore et dolore magna aliqua Ut enim ad minim veniam quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur Excepteur sint occaecat cupidatat non proident sunt in culpa qui officia deserunt mollit anim id est laborum Curabitur pretium tincidunt lacus Nulla gravida orci a odio Nullam varius turpis et commodo pharetra est eros bibendum elit nec luctus magna felis sollicitudin mauris Integer in mauris eu nibh euismod gravida Duis ac tellus et risus vulputate vehicula Donec lobortis risus a elit Etiam tempor ultricies mi Proin gravida orci porttitor iaculis sapien eros vehicula velit eget egestas augue orci ac sem Donec bibendum quam in tellus Nullam cursus pulvinar lectus Pellentesque egestas nisl)
  def random_text(expected_len \\ 200, actual_len \\ 0, text \\ "") when actual_len < expected_len do
    text = "#{text} #{Enum.random(@lorem_words)}"
    random_text(expected_len, String.length(text), text)
  end
  def random_text(_expected_len, _actual_len, text) do
    String.capitalize(String.trim(text))
  end

  @adjectifs ["fabuleux", "incroyable", "inouï", "invraisemblable", "décoiffant", "véritable", "déconcertant"]
  def random_adjectif do
    Enum.random(@adjectifs)
  end

  @doc """
  @return %NaiveDateTime{} La date de maintenant
  """
  def now do
    NaiveDateTime.utc_now()
  end

  @doc """
  Retourne une date aléatoire par rapport à maintenant

  random_time/0   retourne une date autour de maintenant, avant ou 
                  après, dans un intervalle de 1 000 000 de minutes

  random_time/1   retourne une date soit avant soit après dans un
                  intervalle aléatoire de minutes.
                  :after ou :before en premier argument.

  random_time/2   ( :after|:before, Integer.t() )
                  retourne une date soit avant soit après dans un
                  intervalle fixé de minutes.
                  
  random_time/2   (:after|:before, NaiveDateTime.t())
                  Retourne une date avant ou après la date de réfé-
                  rence dans un intervalle de 1 000 000 de minutes
  
  random_time/3   (:after|:before, NaiveDateTime.t(), Integer.t())
                  Retourne une date avant ou après la date de réfé-
                  rence dans un intervalle de minutes fixés (par le
                  troisième argument)

  random_time/3   (:between, NaiveDateTime.t(), NaiveDateTime.t())
                  Retourne une date aléatoire entre les deux dates
                  fournie.

  """
  # Sans rien du tout
  def random_time() do
    random_time(1_000_000)
  end
  # Juste avec le laps, c'est une date autour de maintenant
  def random_time(max_laps) when is_integer(max_laps) do
    random_time(NaiveDateTime.utc_now(), max_laps)
  end
  # Positionnée avant ou après sans laps précisé
  # @param {Atom} position  Soit :after soit :before
  def random_time(position) when is_atom(position) do
    random_time(position, 1_000_000)
  end
  def random_time(ref_time) when not is_atom(ref_time) and not is_integer(ref_time) do
    random_time(ref_time, 1_000_000)
  end
  # Positionnée avant ou après
  def random_time(position, max_laps) when is_atom(position) and is_integer(max_laps) do
    random_time(position, NaiveDateTime.utc_now(), max_laps)
  end
  def random_time(position, ref_time) when is_atom(position) and not is_integer(ref_time) do
    random_time(position, ref_time, 1_000_000)
  end
  def random_time(ref_time, max_laps) when not is_atom(ref_time) and is_integer(max_laps) do
    ref_time
    |> NaiveDateTime.add(Enum.random((-max_laps..max_laps)), :minute)
  end
  # AVANT une date de référence fournie, dans un intervalle donné
  # en minute
  def random_time(:before, ref_time, max_laps) do
    ref_time
    |> NaiveDateTime.add(Enum.random((-max_laps..-1)), :minute)
  end
  # APRÈS une date de référence fournie, dans un intervalle donné
  # en minute
  def random_time(:after, ref_time, max_laps) do
    ref_time
    |> NaiveDateTime.add(Enum.random((1..max_laps)), :minute)
  end
  def random_time(:between, time_before, time_after) do
    diff = NaiveDateTime.diff(time_after, time_before, :minute)
    NaiveDateTime.add(time_before, Enum.random((0..diff)), :minute)
  end



end