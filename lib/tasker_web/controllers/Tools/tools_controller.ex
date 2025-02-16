defmodule TaskerWeb.ToolsController do
  use TaskerWeb, :controller

  def run_script(conn, params) do 
    IO.inspect(params, label: "PARAMS")

    retour = run(params["script"], params["script_args"])
    conn
    |> json(retour)
    |> halt()
  end

  def run("create_note", args) do
    
    IO.inspect(args, label: "avec les arguments")
    Map.merge(%{note: args}, %{ok: true, error: nil})
  end
end