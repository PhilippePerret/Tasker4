defmodule TaskerWeb.PageHTML do
  @moduledoc """
  This module contains pages rendered by PageController.

  See the `page_html` directory for all templates available.
  """
  use TaskerWeb, :html

  embed_templates "page_html/*"

  def home_localized(assigns) do
    lang = Constants.get(:lang)
    path = "priv/gettext/#{lang}/home.html"
    code = PhilTextFormater.get_phil_text(path)
    assigns = assigns 
    |> assign(:lang, lang)
    |> assign(:code, code)
    ~H"""
    <%= raw @code %>
    """
  end

end
