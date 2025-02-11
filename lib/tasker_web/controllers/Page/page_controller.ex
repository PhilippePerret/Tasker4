defmodule TaskerWeb.PageController do
  use TaskerWeb, :controller

  
  def home(conn, _params) do
    # IO.inspect(Gettext.get_locale(TaskerWeb.Gettext), label: "LOCALE")
    render(conn, :home)
  end
end
