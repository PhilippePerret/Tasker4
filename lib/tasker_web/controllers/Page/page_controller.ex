defmodule TaskerWeb.PageController do
  use TaskerWeb, :controller
  
  def home(conn, _params) do
    conn |> render(:home)
  end

  def help(conn, _params) do
    conn |> render(:help)
  end
end
