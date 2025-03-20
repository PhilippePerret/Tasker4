defmodule Mix.Tasks.Phil.Recompile do
  use Mix.Task

  @shortdoc "Pour forcer la recompilation en cas de problème"

  @moduledoc """
  mix phil.recompile permet de forcer la recompilation de l'app.

  Le problème qui a entrainer cette tâche est le signalement d'un 
  module HTML absent alors qu'il est tout à fait présent.
  Options
  -------
  --start     Pour démarrer aussitôt le server (mix phx.server)
  """
  def run(args) do
    env = Enum.at(args, 0, "dev")
    env = if Enum.member?(["prod","dev","test"], env), do: env, else: "dev"
    start_it      = Enum.member?(args, "--start")
    app_name = get_app_name()
    # msg "Application: #{app_name}"
    _current_folder = Path.absname(".")
    # msg "Dossier courant : #{current_folder}"

    msg "Nettoyage des dépendances…"
    System.cmd("mix", ["deps.clean", "--all"])
    msg "Dépendances nettoyées."

    msg "Nettoyage des dépendances…"
    System.cmd("mix", ["deps.get", "--only #{env}"])
    msg "Dépendances nettoyées."

    msg "Compilation…"
    System.cmd("mix", ["compile", "--force"], env: [{"MIX_ENV", env}])
    msg "Compilation ok."

    msg "Compilation exécutée avec succès."

    if start_it do
      msg "Démarrage du serveur\n(jouer ^c deux fois pour l'arrêter)"
      System.cmd("mix", ["phx.server"], env: [{"MIX_ENV", env}])
    end

  end


  # Affiche un message en console
  defp msg(str) do
    Mix.shell().info(str)
  end

  # Retourne le nom de l'application courante
  defp get_app_name do
    Application.get_application(__MODULE__)
  end
end 