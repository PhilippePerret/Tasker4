defmodule TaskerWeb.PageController do
  use TaskerWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
