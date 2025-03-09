'use strict';
/**
 * Données des types de scripts de tâche
 */

window.SCRIPT_DATA = {
    'worker-script': {
        hname: "Script de travailleur"
      , description: "Un script défini par le travailleur, dans n'importe quel format."
      , defaultTitle: "Jouer le script qui..."
      , argument: "/absolute/path/to/script.ext/or/relative/to/project"
    }
  , 'open-folder': {
        hname: "Ouverture de dossier"
      , description: "Permet d'ouvrir un dossier quelconque"
      , defaultTitle: "Ouvrir le dossier qui…"
      , argument: "/absolute/path/to/folder/or/relative/to/project"
    }
  , 'open-file': {
        hname: "Ouverture de fichier"
      , description: "Permet d'ouvrir un fichier quelconque"
      , defaultTitle: "Ouvrir le fichier qui…"
      , argument: "/absolute/path/to/file/or/relative/to/project"
    }
  , 'new-main-version': {
        hname: "Nouvelle version principale de fichier"
      , description: "Créer une nouvelle version principale du fichier (le 'x' dans x.12.5)"
      , defaultTitle: "Nouvelle version du fichier qui…"
      , argument: '/absolute/path/to/file/or/relative/to/project'
    }
  , 'new-minor-version': {
        hname: "Nouvelle version mineure de fichier"
      , description: "Créer une nouvelle version mineur du fichier (le 'x' dans 12.x.5)"
      , defaultTitle: "Nouvelle version du fichier qui…"
      , argument: '/absolute/path/to/file/or/relative/to/project'
    }
  , 'new-path-version': {
        hname: "Nouvelle version de patch de fichier"
      , description: "Créer une nouvelle version de path du fichier (le 'x' dans 12.5.x)"
      , defaultTitle: "Nouvelle version du fichier qui…"
      , argument: '/absolute/path/to/file/or/relative/to/project'
    }
}
// Ajouter l'identifiant dans la donnée du script
for(var scriptId in SCRIPT_DATA){
  Object.assign(SCRIPT_DATA[scriptId], {id: scriptId})
}