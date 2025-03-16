'use strict';
/**
 * Class CBoxier
 * -------------
 * (pour "Checkbox-ier") Gestion des listes de choix multiple
 * 
 * TODO
 *  - bouton pour tout sélectionner (MESSAGE['check_all'])
 *  - bouton pour tout désélectionner (MESSAGE['uncheck_all'])
 * 
 * @usage
 * 
 *    cbs = new CBoxier(data, options)
 *    
 *    Les data définissent data.onOk qui définit une fonction qui
 *    sera appelée avec, en premier argument, l'état des sélections
 *    Par défaut, c'est une table contenant TOUTES les clés, avec 
 *    pour valeur True si elles sont cochées et False dans le cas
 *    contraire. Mais si options.return_checked_keys est True, le
 *    retour sera alors une liste {Array} ne contenant que les clés
 *    cochées.
 * 
 *    cbs.show()          Ouvrir pour choisir des valeurs en les 
 *                        cochant
 *                        Note : la fenêtre est fermée par le click
 *                        sur le bouton OK ou Cancel.
 * 
 * Autres méthodes publiques
 * -------------------------
 * 
 *    cbs.set(keys)       Pour cocher des valeurs à la volée (liste)
 *    cbs.getValues()     Retourne les valeurs cochées (keys)
 *    cbs.check(value)    Pour cocher une valeur (sans ouvrir)
 *    cbs.uncheck(value)  Pour décocher une valeur
 *    cbs.checkAll()      Pour tout cocher. On peut ajouter en argu-
 *                        {except: [liste]} pour tout cocher sauf ces
 *                        valeurs.
 *    cbs.uncheckAll()    Pour tout décocher (le premier argument
 *                        peut aussi être {except: [values]})
 * 
 * +data+
 *    :values {Object|Array}
 *    
 *    Les valeurs des cases à cocher. 
 *    C'est soit une table avec en clé la valeur et en valeur le
 *    label (version simple) :
 *        {key: label, key: label, … }
 *    Soit une liste pouvoir définir plus de choses :
 *        [
 *          {key: key, label: label, checked: true, class: css}
 *        ]
 * 
 *    :id {String}
 *        Identifiant unique du cboxier (calculé par défaut)
 *    :title {String}
 *        Titre à donner au cboxier
 *    :container {DomElement}
 *        L'élément dans lequel on doit mettre le cboxier
 *        document.body par défaut
 *    :onOk
 *        Fonction à appeler quand on clique sur le bouton OK
 *    :onCancle
 *        Fonction à appeler quand on clique sur Cancel
 * 
 * +options+
 *    width:        {Integer} La largeur (en pixels) de la boite, si
 *                  la largeur naturelle ne convient pas.
 *    gutter:       {Integer} Largeur en pixels de la gouttière 
 *                  (espace entre les colonnes — 20px par défaut)
 *    checkeds:     Liste des valeurs (key) cochées
 *                  Note : elles peuvent être précisées aussi par les
 *                  data.
 *    displayType:  Le type du cboxier. Pour le moment, on peut choi-
 *                  sir ces types :
 *                  todo    Les choix les uns au-dessus des autres
 *                  flex3   3 choix côte à côte
 *                  flex4   4 choix côte à côte
 *    :okName
 *        Le nom du bouton "OK" (OK par défaut)
 *    :cancelName
 *        Le nom du bouton "Cancel" (par défaut)
 *    :return_checked_keys
 *        Si True, on retourne une liste (Array) ne contenant que les
 *        clés (valeurs) cochées
 *    
 * 
 */
class CBoxier {
  // Note : les méthodes de classe sont au bout du module

  // ====  PUBLIC METHODS ====

  show(){this.obj.classList.remove('hidden')}
  check(key){
    if ('string' == typeof key) {
      this.cb(key).checked = true
    } else {
      key.forEach(key => {this.check(key)})
    }
  }

  uncheck(key){
    if ('string' == typeof key) {
      this.cb(key).checked = false
    } else {
      key.forEach(key => {this.check(key)})
    }
  }

  /**
   * Pour sélectionner/désectionner toutes les cases à cocher.
   * 
   * @param {Object}  options    Pour des options
   * @param {Array}   options.except Ne pas sélectionner les valeurs
   *                  de cette liste.
   */
  checkAll(options){
    const [ins, outs] = this.onlyCbs(options)
    ins .forEach(dcb => dcb.cb.checked = true)
    outs.forEach(dcb => dcb.cb.checked = false)
  }
  uncheckAll(options){
    const [ins, outs] = this.onlyCbs(options)
    ins .forEach(dcb => dcb.cb.checked = false)
    outs.forEach(dcb => dcb.cb.checked = true)
  }

  // === PRIVATE METHODS ===

  /**
   * Return un doublet contenant la liste des données de case à 
   * cocher (this.cbs) qui répondent à la définition éventuelle de
   * options.except (une liste de valeurs)
   * 
   * @usage
   * 
   *    const ins, outs = this.onlyCbs({except: [values]})
   * 
   * @return [ [dcb retenus], [dcb, exclus] ]
   */
  onlyCbs(options){
    if ( options && options.except && 'object' == typeof options.except && options.except.length) {
      var theIns = [], theOuts = []
      Object.values(this.cbs).each(dcb => {
        if ( options.except.includes(dcb.key) ) {
          theOuts.push(dcb)
        } else {
          thisIns.push(dcb)
        }
      })
      return [theIns, theOuts]
    } else {
      return [Object.values(this.cbs), []]
    }
  }

  hide(){this.obj.classList.add('hidden')}

  get c(){return this.constructor}
  /**
   * 
   */
  constructor(data, options){
    this.data     = this.c.normalizeData(data)
    this.options  = this.c.normalizeOptions(options)
    this.values   = this.checkAndFormateValues(this.data.values, this.options)
    this.build()
    this.observe()
  }

  /**
   * Retourne l'objet Dom de la case à cocher de clé +key+
   */
  cb(key){
    return this.cbs[key]
  }

  /**
   * Construction du cboxier
   */
  build(){
    this.cbs = {} // table pour consigner les cb par clé

    var style = []
    if ( this.options.width ) style.push(`width:${this.options.width}px;`) ;
    style = style.length ? style.join("") : null
    const o = DCreate('DIV', {class:`cboxier hidden ${this.options.displayType}`, style: style})

    // --- Construction du titre ---
    if ( this.data.title ) {
      const title = DCreate('DIV', {class: 'title', text: this.data.title.toUpperCase()})
      o.appendChild(title)
    }

    // --- Lignes de mini-outils ---
    const tmt = DCreate('DIV', {class: 'mini-tools buttons'})
    this.btnCheckAll = DCreate('BUTTON', {class: 'tiny', text: '☑︎☑︎☑︎'})
    this.btnUncheckAll = DCreate('BUTTON', {class: 'tiny', text: '☐☐☐'})
    tmt.appendChild(this.btnCheckAll)
    tmt.appendChild(this.btnUncheckAll)
    o.appendChild(tmt)
    this.btnCheckAll.addEventListener('click', this.checkAll.bind(this))
    this.btnUncheckAll.addEventListener('click', this.uncheckAll.bind(this))

    // --- Construction des checkbox ---
    style = []
    if ( this.options.gutter ) style.push(`column-gap:${this.options.gutter}px;`);
    style = style.length ? style.join("") : null
    const c = DCreate('DIV', {class:'cboxier-cbs', style: style})
    this.values.forEach(dcb => {
      const id  = this.id + "-cb" + dcb.index
      const cb  = DCreate('INPUT', {type: "checkbox", id: id})
      cb.checked = dcb.checked
      cb.dataset.key = dcb.key
      const lab = DCreate('LABEL', {for: id, text: dcb.label})
      const span = DCreate('SPAN', {class: "cboxier-cb"})
      span.appendChild(cb)
      span.appendChild(lab)
      c.appendChild(span)
      Object.assign(this.cbs, {[dcb.key]: {cb: cb, key: dcb.key, cbId: id, label: lab, span: span}})
    })
    o.appendChild(c)

    // --- Construction des boutons ---
    const buttons   = DCreate('DIV', {class:'buttons main'})
    this.okBtn      = DCreate('BUTTON', {class: 'btn-ok', text: this.options.okName})
    this.cancelBtn  = DCreate('BUTTON', {class:'btn-cancel fleft', text: this.options.cancelName})
    buttons.appendChild(this.cancelBtn)
    buttons.appendChild(this.okBtn)
    o.appendChild(buttons)
    this.obj = o
    this.data.container.appendChild(o)
  } // build

  observe(){
    this.okBtn.addEventListener('click', this.onClickOK.bind(this))
    this.cancelBtn.addEventListener('click', this.onClickCANCEL.bind(this))
  }

  onClickOK(ev){
    this.hide()
    this.data.onOk.call(null, this.getValues())
    return stopEvent(ev)
  }
  onClickCANCEL(ev){
    this.hide()
    if ( this.data.onCancel ) this.data.onCancel.call();
    return stopEvent(ev)
  }

  /**
   * Fonction qui retourne les valeurs. C'est une table qui contient
   * en clé la valeur du cb et en valeur True si la case est cochée
   * et False si la case n'est pas cochées
   * 
   * Deux types de retours sont possibles : 
   * si options.return_checked_keys est True, on retourne une liste
   * des clés qui sont sélectionnées, sinon, on retourne une table
   * avec en clé la valeur et en valeur l'état sélectionné/ou non
   */
  getValues(){
    const values = {}
    const okvalues = []
    const returnKeys = this.options.return_checked_keys
    for(var key in this.cbs) {
      const dataCb = this.cbs[key]
      const cb  = dataCb.cb
      if ( returnKeys ) {
        cb.checked && okvalues.push(key)
      } else {
        Object.assign(values, { [key]: cb.checked === true })
      }
    }
    if ( returnKeys ) {
      return okvalues
    } else {
      return values
    }
  }

  get id(){return this.data.id}

  checkAndFormateValues(values, options){
    values || raise("Values required")
    ;('object' == typeof values) || raise(LOC('Array or Table required'))
    var cbIndex = 0, good_values = [];
    if ( undefined == values.length) {
      for( var k in values) {
        const checked = options.checkeds.includes(k)
        good_values.push({index: ++cbIndex, key: k, label: values[k], checked: checked, class: null})
      }
    } else { 
      good_values = values.map(x => {return Object.assign(x, {index: ++cbIndex})})
    }

    return good_values
  }


  // ==== Classe ====

  static init(){

    const styles = DCreate('STYLE', {type: "text/css", text: this.css})
    document.body.appendChild(styles)
  }
  
  static normalizeOptions(options){
    options.okName      || Object.assign(options, {okName: LOC('OK')})
    options.cancelName  || Object.assign(options, {cancelName: LOC('Cancel')})
    options.displayType || Object.assign(options, {displayType: 'flex'})
    options.checkeds    || Object.assign(options, {checkeds: []})
    return options
  }

  static normalizeData(data){
    data.container  || Object.assign(data, {container: document.body})
    data.id         || Object.assign(data, {id: this.newId()})
    return data
  }

  static newId(){
    return "cbier-" + String(Number(new Date()) + Math.random(100))
  }

  static get css(){
    return `
    div.cboxier {
      position: absolute;
      background-color: white;
      box-shadow: 5px 5px 5px 5px #CCCCCC;
      left: 0;
      top: 0;
      font-size: 0.9em;
      padding: 1em;
      z-index: 200;
    }
    div.cboxier.todo {
      min-width: 200px;
      max-width: 200px;
      }
    div.cboxier:not(.todo){
      min-width: 400px;
      max-width: 1000px;
    }
    div.cboxier div.title {
      font-size: 1.1em;
      font-weight: bold;
      margin-bottom: 1em;
    }
    div.cboxier div.cboxier-cbs {
      max-height: 400px;
      overflow: scroll;
    }
    div.cboxier.todo div.cboxier-cbs {
      display: block;
    }
    
    div.cboxier:not(.todo) div.cboxier-cbs {
      display: flex;
      flex-wrap: wrap;
      colum-gap: 20px;
    }

    div.cboxier.todo div.cboxier-cbs span.cboxier-cb {
      display: block;
    }
    div.cboxier:not(.todo) div.cboxier-cbs span.cboxier-cb {
      display:inline-block;
      min-width: 200px;
    }

    div.cboxier div.cboxier-cbs span.cboxier-cb label {
      display: inline!important;
    }
    div.cboxier div.buttons {
      position: relative!important;
      width: calc(100% - 2em);
      text-align: right;
      padding:0!important;
    }

    div.cboxier div.buttons.main {
      padding:1em;
      left:0; bottom:0;
      margin-top:1em;
    }
    div.cboxier div.buttons.main button {
      width: auto!important;
      padding: 0.4em 1em;
    }

    div.cboxier div.buttons.mini-tools {
      height: 40px;
    }
    div.cboxier div.buttons.mini-tools button {
      width: auto!important;
      padding: 2px;
    }
    `
  }

}
window.CBoxier = CBoxier;
window.onload = function(){CBoxier.init()}