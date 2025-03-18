/**
 * Fonction qui reçoit une valeur string (normalement…) et retourne
 * cette valeur, trimée, si elle n'est pas vide, est sinon null
 * 
 * Elle peut être typiquement utilisée pour les valeurs des champs
 * d'édition : 
 *  value = NullIfEmpty(monChamp.value)
 *  // => null si le champ est vide
 */
window.NullIfEmpty = function(value){
  if ( !value ) return null;
  if ( 'string' == typeof value ){
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
  }
  Flash.error(message)
  throw null
}

/**
 * Stop complètement l'évènement donné en argument et retourne False
 */
window.stopEvent = function(ev){
  ev.stopPropagation();
  ev.preventDefault();
  return false
}


window.prettyList = function(list){
  const last = list.pop()
  return list.join(", ") + ", and " + String(last)
}