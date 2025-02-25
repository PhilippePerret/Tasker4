defmodule CommonTestMethods do

  def is_around(sujet, comp, tolerance) do
    sujet > comp - tolerance && sujet < comp + tolerance
  end
end