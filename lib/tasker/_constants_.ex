defmodule Constants do
  @moduledoc """
  Module pour obtenir facilement les constantes partout dans l'appli-
  cation simplement avec : 

      Contants.get(:<key>)
  """

  use Gettext, backend: TaskerWeb.Gettext

  @doc """
  Fonction principale qui retourne la valeur de la clé +key+
  # Examples

    iex> Constants.get(:lang)
    "en"

    iex> Constants.get(:env)
    :test

  """
  def get(key) when is_atom(key) do
    %{
      lang:     Gettext.get_locale(TaskerWeb.Gettext),
      env:      Application.get_env(:tasker, :env),
      app_name: dgettext("tasker", "App Name")
    }[key]
  end
  def get(key) when is_binary(key) do
    get(String.to_atom(key))
  end

end