'use strict';
/**
 * Pour obtenir une locale parmi toutes celles définies dans les
 * fichier gettext de l'application
 * 
 * Pour actualiser les fichiers de locales :
 * 
 *    mix run lib/mix/tasks/generate_locales_js.ex
 * 
 * Ajouter les nouvelles locales uniquement JavaScript dans le
 * fichier : 
 * 
 *  lib/tasker_web/controllers/Tache/js_locales.ex
 * 
 * @usage
 * 
 *      LOC('key-locale')   // => la traduction
 *      LOC('key-locale', [variable])   // => la traduction avec variable ($1 = première, $2 = deuxième)
 *      LOC('key', gender)   // => la traduction genrée 
 *                ^--- 'm' or 'f'
 *      LOC('key', gender, nombre)  // => la version plurielle pour le genre
 * 
 */

window.LANG = navigator.language.slice(0,2);
const path_locales = `./locales-${LANG}.js`;  
 
// On importe les locales que si elles ne sont pas encore en session
if (!sessionStorage.getItem('LOCALES')) {
  import(path_locales).then(_ => {
    Locales.ready = true // dangereux ?
    sessionStorage.setItem('LOCALES', JSON.stringify(LOCALES))
    // console.info("Les locales prêtes mises en session.")
  });
} else {
  window.LOCALES = JSON.parse(sessionStorage.getItem('LOCALES'))
  // console.info("Locales récupérées de session.")
}


class Locales {

  /**
   * 
   * @param {String} key La clé du string à traduire
   * @param {Array} variables Liste des variables. La 1re (index 0) remplacement $1, la 2e (index 1) $2 etc.
   * @param {String} genre 'f' ou 'm' pour 'féminin' ou 'masculin' — non traité pour le moment
   * @param {Integer} count Le nombre (pour pluriel) — non traité pour le moment
   */
  static get(key, variables, gender, count){
    // console.info("-> Locale.get(%s)", key)

    let dataLocale = LOCALES[key]
    if ( !dataLocale ){
      console.error(`La locale « ${key} » est inconnue. Il est impératif de la définir.`)
      dataLocale = `-${key} inconnue-`
    }
    let str = dataLocale.trans || key

    // En présence de variables
    if ( variables ) {
      for (var i = 0, len = variables.length; i < len; ++i){
        str = str.replace(`$${i + 1}`, variables[i])
      }
    }

    return str
  }

}
window.LOC = Locales.get.bind(Locales) // args: key, gender, count