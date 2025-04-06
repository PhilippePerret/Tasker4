defmodule TaskerWeb.PageHTML do
  @moduledoc """
  This module contains pages rendered by PageController.

  See the `page_html` directory for all templates available.
  """
  use TaskerWeb, :html

  embed_templates "page_html/*"

  @doc """
  Page d'accueil localisée
  """
  def home_localized() do
    lang = Constants.get(:lang)
    path = Path.expand("priv/gettext/#{lang}/home.phil")
    PhilHtml.to_html(path, [variables: [app_name: Constants.get(:app_name)]])  
  end

  @doc """
  Affichage de l'aide localisée
  """
  def help_localized do
    lang = Constants.get(:lang)
    path = Path.expand("priv/gettext/#{lang}/help.phil")
    PhilHtml.to_html(path, [variables: [app_name: Constants.get(:app_name)]])  
  end

end