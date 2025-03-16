'use strict';
/**
 * Pour obtenir une locale parmi toutes celles définies dans les
 * fichier gettext de l'application
 * 
 * Pour actualiser les fichiers de locales :
 * 
 *    mix run lib/mix/tasks/generate_locales_js.ex
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
import(`./locales-${LANG}.js`); // définit LOCALES

class Locales {

  /**
   * 
   * @param {String} key La clé du string à traduire
   * @param {Array} variables Liste des variables. La 1re (index 0) remplacement $1, la 2e (index 1) $2 etc.
   * @param {String} genre 'f' ou 'm' pour 'féminin' ou 'masculin' — non traité pour le moment
   * @param {Integer} count Le nombre (pour pluriel) — non traité pour le moment
   */
  static get(key, variables, gender, count){

    if ( 'undefined' != typeof LOCALES ) {
      if ( !sessionStorage.getItem('LOCALES') ) {
        // console.info("Je mets les LOCALES en storage")
        sessionStorage.setItem('LOCALES', JSON.stringify(LOCALES))
      }
    } else {
      window.LOCALES = JSON.parse(sessionStorage.getItem('LOCALES'))
      // console.info("Je dois reprendre les LOCALES du session storage", LOCALES)
    }

    const dataLocale = LOCALES[key] || raise(`La locale « ${key} » est inconnue. Peut-être faut-il actualiser les fichiers locales-<LG>.js`)
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