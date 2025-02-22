defmodule TaskerWeb.WorkerPrefs do
  use TaskerWeb, :controller

  alias Tasker.Accounts
  # alias Tasker.Accounts.Worker

  @doc """
  Affichage et réglage des préférences
  """
  def show(conn, %{"worker_id" => worker_id}) do
    conn = conn
    |> assign(:settings, Accounts.get_worker_settings(worker_id))
    render(conn, :show)
  end

  @doc """
  Enregistrement des préférences
  """
  def update(conn, _params) do
    conn
    # TODO : ENREGISTRER
    |> halt()
  end
end