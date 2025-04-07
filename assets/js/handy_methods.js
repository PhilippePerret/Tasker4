'use strict';

window.now = function(){
  return new Date()
}

/**
 * Méthode permettant de suivre le programme en affichant des retours
 * console avec un certain formatage qui permet de les distinguer des
 * messages ajoutés au besoin.
 * 
 * @usage
 * 
 *  MODE_DEV && spy("<le message>", la donnée)
 */
const SPY_STYLE = "font-size:9pt;color:#999999;font-family:Monospace;"
window.spy = function(message, data){
  let log_data = ['%c' + message, SPY_STYLE]
  if ( undefined !== data ) { log_data.push(data) }
  console.log(...log_data)
}
/**
 * Fonction qui reçoit une valeur string (normalement…) et retourne
 * cette valeur, trimée, si elle n'est pas vide, est sinon null
 * Maintenant, peut recevoir aussi une liste.
 * 
 * Elle peut être typiquement utilisée pour les valeurs des champs
 * d'édition : 
 *  value = NullIfEmpty(monChamp.value)
 *  // => null si le champ est vide
 */
window.NullIfEmpty = function(value){
  if ( !value ) return null;
  if ( 'object' == typeof value && value.length){
    if (value.length) return value;
    else return null;
  } else if ( 'string' == typeof value ){
    value = value.trim()
    if ( value == "" ) return null;
    else return value;
  }
  return value
}

/**
 * Fonction à utiliser dans un try{...}catch(){...} qui permet :
 * 
 * 1) d'utiliser la tournure :  condition || raise("Message d'erreur")
 * 2) de sélectionner le champ fautif (en le définissant en second
 *    argument)
 * 
 * Dépendances
 *  - flash.js/css
 * 
 * @param {String} message Le message d'erreur à afficher
 * @param {DomElement} domField Le champ qui génère éventuellement l'erreur.
 */
window.raise = function(message, domField) {
  if ( domField ) {
    domField.focus()
    domField.select()
    errorizeField(domField)
  }
  Flash.error(message)
  throw null
}
function errorizeField(field) {
  field.classList.add('error')
  field.addEventListener('blur', unErrorizeField.bind(null, field), {once: true})
}
function unErrorizeField(field, ev) {
  field.classList.remove('error')
  return stopEvent(ev)
}

/**
 * Stop complètement l'évènement donné en argument et retourne False
 */
window.stopEvent = function(ev){
  ev.stopPropagation();
  ev.preventDefault();
  return false
}

/**
 * @return {String} Une liste humaine bien formatée
 */
window.prettyList = function(list){
  const last = list.pop()
  return list.join(", ") + LOC(", and") + String(last)
}

/**
 * Si la valeur +value+ peut être un nombre, elle est transformée,
 * sinon, elle est laissée telle quelle
 */
window.parseIntIfNumberish = function(value){
  if ( 'string' == typeof value ){
    if ( isNaN(parseFloat(value)) ) {
      return value
    } else if ( parseFloat(value) == parseInt(value) ) {
      return parseInt(value)
    } else {
      return parseFloat(value)
    }
  } else { return value }
}