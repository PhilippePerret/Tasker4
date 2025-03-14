'use strict';


/*

  ========== SCRIPTS ================

*/
class TaskScript {

  static init(){
    if ( DGet('div.script-form') ) {
      this.feedScriptTypes()
      this.CLONE_BLOCK = DGet('div.script-form').cloneNode(true)
      this.observe()
      this.setData()
    }
  }

  /**
   * Méthode mettant en place les scripts de la tâche
   */
  static setData(){
    let data = NullIfEmpty(this.fieldData.value)
    if ( data && data.length ) {
      data = JSON.parse(data)
      this.listing.innerHTML = ""
      data.forEach(dataScript => {
        const script = this.onAddScript(null)
        script.setData(dataScript)
      })
    } else if (DGet('div.script-form')) {
      this.instancieFirstBlocScript()
    }
  }
  /**
   * Méthode appelée pour obtenir les données des scripts de la
   * tâche.
   */
  static getData(){
    const scriptList = []
    DGetAll('div.script-form', this.listing).forEach(form => {
      const data = {id: null, title: null, type: null, argument: null}
      for(var prop in data){
        data[prop] = DGet(`.script-${prop}`, form).value.trim()
      }
      data.title && data.type && scriptList.push(data)
    })
    this.fieldData.value = JSON.stringify(scriptList)
    return scriptList
  }
  static instancieFirstBlocScript(){
    this.current = new TaskScript(DGet('div.script-form'))
  }
  static feedScriptTypes(){
    const menu = DGet('select.script-type', DGet('div.script-form'))
    Object.values(SCRIPT_DATA).forEach(dscript => {
      const opt = DCreate('OPTION',{})
      opt.setAttribute('value', dscript.id)
      opt.innerHTML = dscript.hname
      menu.appendChild(opt)
    })
  }
  static observe(){
    this.btnAddScript.addEventListener('click', this.onAddScript.bind(this))
  }
  
  static onAddScript(ev){
    const o = this.CLONE_BLOCK.cloneNode(true)
    this.listing.appendChild(o)
    this.current = new TaskScript(o)
    this.current.focus()
    return this.current
  }

  /**
   * Suppression du script fourni en argument. S'il a déjà été 
   * enregistré, il faut le mémoriser pour pouvoir le détruire à 
   * l'enregistrement de la tâche.
   * 
   * @param {TaskScript} script Le script à détruire
   * @param {Event Click} ev L'évènement déclenché
   */
  static onRemove(script, ev){
    const nombreScripts = DGetAll('div.script-form', this.listing).length
    if ( script.id ) {
      let eraseds = NullIfEmpty(this.fieldErased.value)
      eraseds = eraseds ? eraseds.split(';') : []
      eraseds.push(script.id)
      this.fieldErased.value = eraseds.join(';')
    }
    if ( nombreScripts > 1 ) {
      script.obj.remove()
    } else {
      // Dernier bloc, on ne fait que vider ses champs
      script.setData({})
    }
    return false
  }

  static get fieldData(){return this._fielddata || (this._fielddata = DGet('input#task-scripts', this.obj))}
  static get fieldErased(){return this._fielddels || (this._fielddels = DGet('input#task-erased-scripts', this.obj))}
  static get listing(){return this._listing || (this._listing = DGet('div.scripts-list', this.obj))}
  static get btnAddScript(){return this._btnaddscript || (this._btnaddscript = DGet("button.btn-add", this.obj))}
  static get btnSaveScripts(){return this._btnsavescpt || (this._btnsavescpt = DGet("button.btn-save-script", this.obj))}
  static get obj(){return this._obj || (this._obj = DGet('div#task_scripts-container'))}


  constructor(o){
    this.obj = o
    this.prepare()
    this.observe()
  }
  prepare(){
  }
  observe(){
    this.btnRemove.addEventListener('click', TaskScript.onRemove.bind(TaskScript, this))
    this.menuType.addEventListener('change', this.onChooseType.bind(this))
  }
  setData(data){
    // console.log("<script>.setData", data)
    this.fieldId.value        = data.id || ""
    this.fieldTitle.value     = data.title || ""
    this.fieldArgument.value  = data.argument || ""
    this.menuType.value       = data.type || "---"
    this.onChooseType()
  }
  focus(){
    this.fieldTitle.focus()
  }
  // Choix d'un type
  onChooseType(ev){
    const dScript = SCRIPT_DATA[this.menuType.value]
    this.fieldDescription.innerHTML = dScript.description
    this.fieldArgument.setAttribute('placeholder', "Attendu : " + dScript.argument)
  }

  get id(){return NullIfEmpty(this.fieldId.value) }

  get fieldId(){return this._fieldid || (this._fieldid = DGet('input.script-id', this.obj))}
  get fieldTitle(){return this._fieldtitle || (this._fieldtitle = DGet('input.script-title', this.obj))}
  get fieldArgument(){return this._fieldarg || (this._fieldarg = DGet('textarea.script-argument', this.obj))}
  get fieldDescription(){return this._fielddes ||(this._fielddes = DGet('.script-description', this.obj))}
  get menuType(){return this._menutype || (this._menutype = DGet('select.script-type', this.obj))}
  get btnRemove(){return this._btnclose || (this._btnclose = DGet('button.btn-close', this.obj))}

}

window.TaskScript = TaskScript;