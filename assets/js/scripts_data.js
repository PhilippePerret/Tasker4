'use strict';
/**
 * Données des types de scripts de tâche
 */

window.SCRIPT_DATA = {
    '': {
        hname: '---'
      , description: ''
      , defaultTitle: ''
      , argument: '(description de l’argument)'
    }
  , 'worker-script': {
        hname: "Script personnel"
      , description: "Un script défini par le travailleur, dans n'importe quel format."
      , defaultTitle: "Jouer le script qui..."
      , argument: '{path:"/absolute/path/to/script.ext" ou "relative/to/project", args:[liste des arguments]}'
    }
  , 'open-folder': {
        hname: "Ouverture de dossier"
      , description: "Permet d'ouvrir un dossier quelconque"
      , defaultTitle: "Ouvrir le dossier qui…"
      , argument: '"/absolute/path/to/folder" OU "relative/to/project"'
    }
  , 'open-file': {
        hname: "Ouverture de fichier"
      , description: "Permet d'ouvrir un fichier quelconque"
      , defaultTitle: "Ouvrir le fichier qui…"
      , argument: '"/absolute/path/to/file" OU "relative/to/project"'
    }
  , 'new-main-version': {
        hname: "Nouvelle version principale de fichier"
      , description: "Créer une nouvelle version principale du fichier (le 'x' dans x.12.5)"
      , defaultTitle: "Nouvelle version du fichier qui…"
      , argument: '"/absolute/path/to/file-X.Y.Z" OU "relative/to/project" (-X.Y.Z sera recherché en tant que numéro de version courante)'
    }
  , 'new-minor-version': {
        hname: "Nouvelle version mineure de fichier"
      , description: "Créer une nouvelle version mineur du fichier (le 'x' dans 12.x.5)"
      , defaultTitle: "Nouvelle version du fichier qui…"
      , argument: '"/absolute/path/to/file-X.Y.Z" OU "relative/to/project" (-X.Y.Z sera recherché en tant que numéro de version courante)'
    }
  , 'new-patch-version': {
        hname: "Nouvelle version de patch de fichier"
      , description: "Créer une nouvelle version de path du fichier (le 'x' dans 12.5.x)"
      , defaultTitle: "Nouvelle version du fichier qui…"
      , argument: '"/absolute/path/to/file-X.Y.Z" OU "relative/to/project" (-X.Y.Z sera recherché en tant que numéro de version courante)'
    }
}
// Ajouter l'identifiant dans la donnée du script
for(var scriptId in SCRIPT_DATA){
  Object.assign(SCRIPT_DATA[scriptId], {id: scriptId})
}