defmodule TaskerWeb.TaskTimeHTML do
  use TaskerWeb, :html

  embed_templates "task_time_html/*"

  @doc """
  Renders a task_time form.
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true

  def task_time_form(assigns)
end
