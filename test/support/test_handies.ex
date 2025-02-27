defmodule TestHandies do

  def equal_with_tolerance?(sujet, compar, tolerance) do
    if sujet == compar do
      true
    else
      delta =
      if is_binary(tolerance) && String.ends_with?(tolerance, "%") do
        tolerance
        |> String.slice((0..-2//1))
        |> (fn s -> String.contains?(s, ".") && String.to_float(s) || String.to_integer(s) end).()
        |> (fn x -> sujet * x / 100 end).()
        |> (fn x -> x > 5 && x || 5 end).() # minimum 5
        # |> IO.inspect(label: "Tolérance pour #{sujet}")
      else 
        tolerance
      end
      compar >= (sujet - delta) and compar <= (sujet + delta)
    end
  end

  def debug_tasks(liste, properties \\ [], titre \\ nil) do
    if !is_nil(titre) do
      IO.puts "---> #{titre} <---"
    end

    liste
    |> Enum.each(fn tk ->
      props = [tk.id]
      props = props ++ ["[rank=#{tk.rank.value}]"]
      props = props ++ Enum.map(properties, fn prop -> 
        case prop do
          :natures ->    if !is_nil(titre) do
      IO.puts "---> #{titre} <---"
    end

            first_nature = Enum.at(tk.natures, 0)
            case first_nature do
            nil -> "natures = []"
            nature when is_binary(nature) -> 
              "natures = " <> Enum.join(tk.natures, ", ")
            _ ->
              "natures = " <> (Enum.map(tk.natures, fn nat -> nat.id end) |> Enum.join(", "))
            end
          _ -> 
            "prop = #{inspect tk[prop]}"
        end
      end)

      IO.puts "- T. #{Enum.join(props, " - ")}"
    end)

    if !is_nil(titre) do
      IO.puts "<--- /#{titre} --->"
    end

    liste
  end



end