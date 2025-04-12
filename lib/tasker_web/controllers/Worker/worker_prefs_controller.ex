defmodule TaskerWeb.WorkerPrefs do
  use TaskerWeb, :controller

  alias Tasker.Accounts


  @doc """
  Affichage des préférences
  """
  def show(conn, _params) do
    worker_id = conn.assigns.current_worker.id
    conn = conn
    |> assign(:settings_specs, @settings_specs)
    |> assign(:settings, Accounts.get_worker_settings(worker_id))
    render(conn, "show.html")
  end

  @doc """
  Réglage des préférences
  """
  def edit(conn, _params) do
    worker_id = conn.assigns.current_worker.id
    conn = conn
    |> assign(:settings, Accounts.get_worker_settings(worker_id))
    render(conn, :edit)
  end

  @doc """
  Enregistrement des préférences
  """
  def update(conn, params) do
    _worker_id = conn.assigns.current_worker.id
    conn = conn
    # TODO ENREGISTRER
    show(conn, params)
  end
end