defmodule TaskerWeb.WorkerPrefs do
  use TaskerWeb, :controller

  alias Tasker.Accounts
  # alias Tasker.Accounts.Worker

  @doc """
  Affichage des préférences
  """
  def show(conn, %{"worker_id" => worker_id}) do
    conn = conn
    |> assign(:settings, Accounts.get_worker_settings(worker_id))
    render(conn, :show)
  end

  @doc """
  Réglage des préférences
  """
  def edit(conn, %{"worker_id" => worker_id}) do
    conn = conn
    |> assign(:settings, Accounts.get_worker_settings(worker_id))
    render(conn, :edit)
  end

  @doc """
  Enregistrement des préférences
  """
  def update(conn, params) do
    conn = conn
    # TODO ENREGISTRER
    show(conn, params)
  end
end