defmodule Constants do
  @moduledoc """
  Module pour obtenir facilement les constantes partout dans l'appli-
  cation simplement avec : 

      Contants.get(:<key>)
  """

  @env Application.compile_env(:tasker, :env)

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
      lang:   Gettext.get_locale(TaskerWeb.Gettext),
      env:    @env
    }[key]
  end
  def get(key) when is_binary(key) do
    get(String.to_atom(key))
  end

end