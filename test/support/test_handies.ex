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
        |> IO.inspect(label: "Tolérance pour #{sujet}")
      else 
        tolerance
      end
      compar >= (sujet - delta) and compar <= (sujet + delta)
    end
  end
end