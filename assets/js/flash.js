'use strict';

/**
 * Quatre types de message :
 * 
 *  - info/notice
 *  - success
 *  - warning (alerte)
 *  - error
 */
class Flash {
  static init(){
    // console.info("Initialisation de Flash")
  }
  static notice(message) {
    this.buildMessage({content: message, type: 'notice'})
  }
  static info(message){return this.notice(message)}

  static success(message){
    this.buildMessage({content: message, type: 'info success'}) // TODO: CSS faire la class success
  }
  static warning(message) {
    this.buildMessage({content: message, type: 'warning'})
  }
  static error(message) {
    this.buildMessage({content: message, type: 'error'})
  }

  static buildMessage(data){
    new FlashMessage(data)
  }

  /**
   * Pour détruire un message affiché
   */
  static removeMessage(message){
    if ( message.type != 'error') {
      clearTimeout(message.timer);
      message.timer = null
    }
    message.obj.remove()
    message = undefined
  }

  static get conteneur(){
    return this._maincont || (this._maincont = document.querySelector("#flash-group"))
  }
}

class FlashMessage {
  constructor(data){
    // console.log("data", data)
    this.data = data
    this.build()
    this.show()
    if ( this.type != 'error' ) this.temporize();
    this.observe()
  }

  build(){
    const msg = document.createElement('DIV')
    msg.className = `flash-message ${this.type}`
    msg.innerHTML = this.content
    this.obj = msg
  }

  show(){
    Flash.conteneur.appendChild(this.obj)
  }

  observe(){
    this.obj.addEventListener('click', this.onClick.bind(this))
  }

  onClick(ev){
    Flash.removeMessage(this)
  }

  temporize(){
    this.timer = setTimeout(Flash.removeMessage.bind(Flash, this), 2000 + this.readingTime)
  }

  get readingTime(){
    return this.content.split(" ").length * 300 * 4
  }

  get content(){return this.data.content}
  get type(){return this.data.type}
}

window.Flash = Flash

// console.log("flash.js chargé ! (dans flash.js")