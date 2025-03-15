defmodule TaskerWeb.ProjectHTML do
  use TaskerWeb, :html
  
  embed_templates "project_html/*"

  @doc """
  Renders a project form.
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true

  def project_form(assigns)

  attr :project, :string, required: true
  def project_title(assigns) do
    ~H"""
    <%= gettext("OPEN_GUIL") %>{@project.title}<%= gettext("CLOSE_GUIL") %>
    """
  end
end
