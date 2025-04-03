defmodule Mix.Tasks.App.Compile do
  use Mix.Task

  @shortdoc "Recompile complètement l'application (et produit une release)"

  @moduledoc """
  Ce mix permet de jouer toutes les commandes pour la production de 
  l'application en production ou en développement. L'environnement,
  :dev par défaut, doit être précisé en second argument :

    > mix app.compile prod

  Si l'on veut lancer le server tout de suite après, on ajoute 
  l'option --start à la commande :

    > mix app.compile prod --start

  Sinon, on peut lancer la release en production à l'aide de :

    > _build/prod/rel/tasker/bin/tasker start

  … et l'application démarre sur le port 4001 (mais normalement, si
  le serveur a bien été lancé, un lien devrait permettrait d'ouvrir
  directement l'appli dans le navigateur)

  Options
  -------

  --start     Démarre le serveur après la compilation
  --ecto      Reset tout ce qui concerne la base de données. Atten-
              tion, si c'est en production, cela détruira toutes les
              données actuelles.
  --release   Poursuit la compilation en produisant la release.
              Note : avec cette option et l'option --start, c'est la
              release qui est démarrée.
  """
  def run(args) do
    env = Enum.at(args, 0, "dev")
    start_it      = Enum.member?(args, "--start")
    setup_ecto    = Enum.member?(args, "--ecto")
    make_release  = Enum.member?(args, "--release")
    app_name = get_app_name()
    msg "Application: #{app_name}"
    current_folder = Path.absname(".")
    # msg "Dossier courant : #{current_folder}"

    if setup_ecto do
      msg "Initialisation (setup) de la base de données"
      System.cmd("mix", ["ecto.setup"], env: [{"MIX_ENV", env}])
      msg "Base de données initialisée"
    end

    msg("Création des dépendances…")
    System.cmd("mix", ["deps.get", "--only #{env}"])
    msg("Dépendances ok")

    msg("Compilation…")
    System.cmd("mix", ["compile"], env: [{"MIX_ENV", env}])
    msg("Compilation ok.")

    msg("Nettoyage des assets…")
    System.cmd("mix", ["phx.digest.clean", "--all"])
    msg("Assets nettoyées.")

    msg("Déploiement des assets…")
    System.cmd("mix", ["assets.deploy"], env: [{"MIX_ENV", env}])
    msg("Assets déployées.")

    msg "Compilation exécutée avec succès."

    if make_release do
      msg "Production de la release…"
      System.cmd("mix", ["phx.gen.release"])
      System.cmd("mix", ["release", "--force", "--overwrite"], env: [{"MIX_ENV", env}])
      msg "Release produite avec succès."
    end

    if start_it do
      msg "Démarrage du serveur en mode production…\n(jouer ^c deux fois pour l'arrêter)"
      if make_release do
        full_command = Path.join([current_folder, "_build/prod/rel/#{app_name}/bin/#{app_name}"])
        System.cmd(full_command, ["start"])
      else
        System.cmd("mix", ["phx.server"], env: [{"MIX_ENV", env}])
      end
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