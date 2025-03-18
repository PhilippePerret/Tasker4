'use strict';
/**
 * Gestion de l'interface
 */
class UI {

  /**
   * Méthode appelée pour gérer le retour en arrière. Il fonctionne
   * en définissant la variable session "back" constitué de deux 
   * élément : <route>|<nom du bouton>
   * 
   * Cette fonction est toujours appelée, en fin de téléchargement, 
   * pour régler l'éventuel bouton pour revenir en arrière. C'est un
   * bouton de class "back-btn".
   * 
   * Pour définir le bouton
   * ----------------------
   * 
   *  <button class="back-btn" data-default_back="<route>|<nom bouton>"></button>
   * 
   * Si default_back n'est pas défini, le bouton ne sera pas affiché
   * si 'back' n'est pas défini en session.
   * 
   * Pour définir le retour
   * ----------------------
   * Mettre dans la fonction qui fait passer à l'autre page :
   * 
   *  sessionStorage.setItem('back', "<route>|<nom bouton>")
   * 
   * Note : 
   * 
   *  1)  ne pas mettre la flèche au nom du bouton, elle sera ajou-
   *      tée automatiquement.
   *  2)  l'item 'back' de session sera automatiquement supprimé.
   * 
   */
  static setBackButton(){
    [this.backRoute, this.backButtonName] = (sessionStorage.getItem('back')||"").split("|").map(x => {return NullIfEmpty(x)})
    console.info("[setBackButton] backRoute='%s', backButtonName='%s'", this.backRoute, this.backButtonName)
    DGetAll('.back-btn').forEach(bouton => {
      let backRoute, backName = this. backButtonName;
      if ( this.backRoute ) {
        backRoute = this.backRoute
      } else {
        [backRoute, backName] = bouton.dataset.default_back.split('|').map(s => {return NullIfEmpty(s)})
      }
      if ( backRoute ) {
        bouton.innerHTML = "↖︎ " + NullIfEmpty(backName) || "Retour"
        bouton.addEventListener('click', this.onClickBackButton.bind(this, backRoute))
      } else {
        // Si le bouton ne définit pas de back, ni en live, ni par
        // défaut, on le cache.
        bouton.classList.add('hidden')
      }
    })
  }
  static onClickBackButton(backRoute, ev){
    sessionStorage.removeItem('back')
    window.location.href = backRoute
    return stopEvent(ev)
  }
}

window.UI = UI

window.addEventListener('load', function(){
  console.log("-> init UI")
  UI.setBackButton()
})
window.onload = function(){
}

console.log("Fin chargement ui.js")