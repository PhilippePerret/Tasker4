defmodule Tasker do
  @moduledoc """
  Tasker keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  @doc """
  Retourne la version courante de l'application

  @usage
      Tasker.version()

  """
  def version do
    to_string(Application.spec(:tasker, :vsn))
  end
end
