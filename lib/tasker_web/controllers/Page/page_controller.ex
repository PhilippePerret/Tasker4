defmodule TaskerWeb.PageController do
  use TaskerWeb, :controller
  
  def home(conn, _params) do
    conn
    |> render(:home)
  end
end
