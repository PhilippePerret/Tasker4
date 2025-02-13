defmodule TaskerWeb.TaskHTML do
  use TaskerWeb, :html

  embed_templates "task_html/*"

  @doc """
  Renders a task form.
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true
  attr :projects, :list, required: true

  def task_form(assigns)

  @doc """
  Renders a task_spec form.
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true

  def task_spec_form(assigns)

end
