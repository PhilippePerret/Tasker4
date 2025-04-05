'use strict';
/**
 * Class DiscreteMessage
 * version 0.1.0
 * Pour afficher des messages discrets dans l'application
 * 
 * On peut définir leur emplacement et leur niveau de discrétion.
 * 
 * Voir le constructeur pour le détail des données.
 */
class DiscreteMessage {

  // ======== I N S T A N C E ===========

  /**
   * Pour instancier un message discret
   * 
   * @param {Object}  data Les données à prendre en considération.
   * @param {String}  data.content Contenu du message (donc le texte).
   * @param {Integer} data.discretion Un nombre de 0 à 9 déterminant la discrétion. 9 = super discret, 0 = presque pas discret
   * @param {Boolean} data.once   Si True (défaut), le message sera détruit après utilisation.
   * @param {Boolean} data.type   Le type de message parmi 'notice' (défaut), 'success', 'error'
   * @param {Integer} data.width   Le nombre de pixels en largeur (par défaut : 680)
   * @param {Boolean} data.keep   Si True, le message restera en place jusqu'à ce que l'utilisateur clique dessus.
   * @param {String}  data.position 'top-left', 'top-right', 'bottom-left' ou 'bottom-right'
   * @param {Integer} data.duration  Nombre de secondes d'affichage du message (calculé par défaut)
   */
  constructor(data) {
    this.data = this.defaultize(data)
    this.built = false
  }

  show(){
    this.built || this.build()
    this.obj.classList.remove('hidden')
  }

  hide(){
    if ( this.timer ) {
      clearTimeout(this.timer)
      delete this.timer
    } 
    if ( this.data.once ){ this.obj.remove() }
    else { this.obj.classList.add('hidden')}
  }

  /**
   * Construction du message
   */
  build(){
    const objId = `discmsg-${Number(new Date())}`
    const o = DCreate('DIV', {id: objId, class: `${this.data.type} hidden`, style: this.containerStyle})
    o.appendChild(DCreate('DIV', {class:'content', text: this.data.content}))
    this.obj = o
    document.body.appendChild(o)
    this.observe()
    this.built = true
  }
  observe(){
    this.obj.addEventListener('click', this.hide.bind(this))
    if ( !this.data.keep ) {
      this.timer = setTimeout(this.hide.bind(this), this.data.duration * 1000)
      console.log("Durée d'affichage en secondes", this.data.duration)
    }
  }


  get containerStyle(){
    return `
    position:absolute
    display:inline-block
    width:${this.data.width}px
    ${this.calcPosition()}
    padding:0.3em 0.5em
    border:1px solid #CCC
    border-radius:12px
    opacity:${this.calcDiscretion()}
    z-index:250
    `.trim().replace(/\n/g, ";")
  }
  /**
   * Met les valeurs par défaut dans les données
   */
  defaultize(data){
    if (undefined === data.position) Object.assign(data, {position: 'top-left'})
    if (undefined === data.keep) Object.assign(data, {keep: false})
    if (undefined === data.once) Object.assign(data, {once: true})
    if (undefined === data.type) Object.assign(data, {type: 'notice'})
    if (undefined === data.width) Object.assign(data, {width: 680})
    if (undefined === data.content) Object.assign(data, {content: "Message sans contenu…"})
    if (undefined === data.duration) Object.assign(data, {duration: this.calcDuration(data.content)})
    if (undefined === data.discretion) Object.assign(data, {discretion: 3})

    return data
  }

  /**
   * Calcule le temps d'affichage en fonction de la longueur du
   * contenu. Retourne le nombre de secondes.
   * 
   * @return {Integer} Nombre de secondes
   */
  calcDuration(str){
    return (str.split(' ').length * 300 * 4) / 1000
  }

  /**
   * Retourne un nombre de 1 à 0.1 représentation la discrétion du
   * message (qui correspond à l'opacité, donc 1 = normalement 
   * visible et 0.1 presque invisible)
   */
  calcDiscretion(){
    return (1 - (this.data.discretion / 10)).toFixed(1)
  }

  /**
   * @return La position du message en fonction des données
   */
  calcPosition(){
    let [posY, posX] = this.data.position.split('-')
    switch(posY){
      case 'top':     posY = 'top:60px'; break
      case 'bottom':  posY = 'bottom:60px'; break
      default:        posY = 'top:60px'
    }
    switch(posX){
      case 'left':    posX = 'left:120px'; break
      case 'right':   posX = 'right:60px'; break
      default:        posX = 'left:120px'
    }
    return `${posX};${posY}`
  }

}
window.DiscreteMessage = DiscreteMessage;