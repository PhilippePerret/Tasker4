'use strict';

class UIMasker {

  /**
   * Instanciation d'un nouveau masque de page
   * 
   * @param {Object}    data Table des données
   * @param {String}    data.title  Le message "titre" à afficher
   * @param {Function}  data.onclick Fonction à appeler en cas de click sur le masque
   * @param {String}    data.onclick Ou le message à afficher si c'est un string
   * @param {Integer}   data.counterback Date future, en millisecondes, pour le compte à rebours
   * @param {Function}  data.ontime  La fonction à appeler en fin de compte à rebours
   * 
   */
  constructor(data){
    this.data = data || {}
    this.built = false
  }

  get counterback(){return this.data.counterback}

  activate(){
    this.built || this.build()
    this.show()
    if ( this.counterback ) this.startCounterback() ;
  }
  desactivate(){
    if ( this.counterback ) this.stopCounterback() ;
    this.hide()
  }
  show(){this.obj.classList.remove('hidden')}
  hide(){this.obj.classList.add('hidden')}

  build(){
    const o = DCreate('DIV', {id:'ui-mask', style:`position:fixed;top:0;left:0;width:${window.outerWidth}px;height:${window.outerHeight}px;z-index:5000`})
    const m = DCreate('DIV', {id:'ui-mask-mask', style:`width:${window.outerWidth}px;height:${window.outerHeight}px;z-index:5000;background-color:#CCCCCC;opacity:0.8;`})
    const h = DCreate('DIV', {id:'ui-mask-horloge', style: `position:absolute;left:200px;top:calc(45%);z-index:5001;`})
    const f = DCreate('DIV', {id:'ui-mask-message', style:'position:absolute;left:200px;top:100px;font-size:24pt;z-index:5001;'})
    const t = DCreate('DIV', {id:'ui-mask-title', style:'position:absolute;left:200px;top:calc(40%);font-size:24pt;z-index:5001;'})
    const c = DCreate('DIV', {id:'ui-mask-btn-close', style:'position:absolute;top:10px;left:10px;font-size:34pt; font-family:Arial;color:white;z-index:5001;cursor:pointer;', text: 'x'})
    o.appendChild(m)
    o.appendChild(f)
    o.appendChild(t)
    o.appendChild(h)
    o.appendChild(c)
    document.body.appendChild(o)
    this.obj          = o
    this.btnClose     = c
    this.fieldHorloge = h
    this.fieldMessage = f
    this.fieldTitle   = t

    if ( this.data.title ) this.showTitle(this.data.title)

    // Réaction au click
    if ( 'string' == typeof this.data.onclick ){
      this.data.onclick = this.showMessage.bind(this, String(this.data.onclick))
    }
    o.addEventListener('click', this.data.onclick)
    this.btnClose.addEventListener('click', this.onForceStop.bind(this))

    this.built        = true
  }

  showTitle(title){
    this.fieldTitle.innerHTML = title
  }
  showMessage(message){
    this.clearTimerMessageIfAny()
    this.fieldMessage.innerHTML = message
    this.timerMsg = setTimeout(this.cleanupMessage.bind(this), 20 * 1000)
  }
  cleanupMessage(){
    this.clearTimerMessageIfAny()
    this.fieldMessage.innerHTML = ""
  }
  clearTimerMessageIfAny(){
    if (this.timerMsg) {
      clearTimeout(this.timerMsg)
      delete this.timerMsg
    }
  }

  startCounterback(){
    this.fieldHorloge.style.fontSize   = '30pt'
    this.fieldHorloge.style.fontFamily = 'Monospace'
    this.fieldHorloge.innerHTML = Horloge.s2h(this.counterback)
    this.timer = setInterval(this.runCounterback.bind(this), 500)
  }
  runCounterback(){
    const laps = this.counterback - (new Date()).getTime()
    if ( laps < 0 ) { 
      this.stopCounterback() 
    }
    else {
      this.fieldHorloge.innerHTML = Horloge.s2h(Math.round(laps / 1000))
    }
  }
  stopCounterback(){
    clearInterval(this.timer)
    this.timer = null
    this.hide()
    this.data.ontime.call()
  }

  onForceStop(ev){
    ev.stopPropagation()
    if ( this.data.onforceStop ){
      this.data.onforceStop.call()
    }
    this.desactivate()
    return false
  }

}

window.UIMasker = UIMasker