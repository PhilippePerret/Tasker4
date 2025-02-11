defmodule TaskerWeb.WorkerHTML do
  use TaskerWeb, :html

  embed_templates "worker_html/*"

  @doc """
  Renders a worker form.
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true

  def worker_form(assigns)
end
