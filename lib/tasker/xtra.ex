defmodule XTra.Map do

  def to_binary_keys(map) when is_map(map) do
    Enum.reduce(map, %{}, fn {key, val}, new_map ->
      new_key =
        cond do
        is_binary(key) -> key
        is_atom(key) -> Atom.to_string(key)
        true -> key # inconnue
        end
      Map.put(new_map, new_key, val)
    end)
  end

  def to_atom_keys(map) when is_map(map) do
    Enum.reduce(map, %{}, fn {key, val}, new_map ->
      new_key =
        cond do
        is_binary(key)  -> String.to_atom(key)
        is_atom(key)    -> key
        true -> key # inconnue (peut poser problème)
        end
      Map.put(new_map, new_key, val)
    end)
  end
end