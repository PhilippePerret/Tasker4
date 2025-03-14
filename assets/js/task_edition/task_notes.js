'use strict';
/**
 * Gestion du blocnotes de la tâche
 * 
 * Notes
 * -----
 * 
 *  - Contrairement à d'autres propriétés, ces notes sont enregis-
 *    trées dès leur création et leur modification.
 */

const NOTES_PROPERTIES = {
    id:           {name: "Identifiant de la note"}
  , title:        {name: "Titre de la note"}
  , details:      {name: "Détail de la note"}
  , task_spec_id: {name: "ID de la fiche task-spec"}
}

class Blocnotes {
  static init(){
    NoteEditor.init()
    this.buildNotes()
  }

  /**
   * À l'ouverture, on construit le listing des notes de la tâche
   */
  static buildNotes(){
    let dataNotes = NullIfEmpty(DGet('input#blocnotes-notes', this.obj).value)
    if ( dataNotes === null ) return ;
    dataNotes = JSON.parse(dataNotes)
    // console.log("Affichage des notes", dataNotes)

    dataNotes.forEach(dnote => {
      Object.assign(dnote, {task_spec_id: Task.TaskSpecId})
      const note = new Blocnotes(dnote)
      note.build()
    })
  }

  static get listing(){
    return this._listing || (this._listing = DGet('div#blocnotes-note-list', this.obj))
  }
  static get obj(){
    return this._obj || (this._obj = DGet('div#blocnotes-container'))
  }

  // =========  I N S T A N C E   N O T E  =============

  constructor(data){
    this.data = data
  }

  // Persistent Data
  get id(){return this.data.id}
  get title(){return this.data.title}
  get details(){return this.data.details}
  get task_spec_id(){return this.data.task_spec_id}
  get author(){return this.data.author}
  get inserted_at(){return this.data.inserted_at}
  // Volatile Data
  get pseudo(){return this.author ? this.author.pseudo : "anonyme"}
  get humanDate(){return this._hdate || (this.hdata = this.defineHumanDate())}

  // Pour construire l'affichage de la note
  build(){
    const o = DCreate('DIV', {class:'note'})
    o.appendChild(DCreate('button', {class:'note-btn-sup tiny fright', type:'button', text:'🗑️', title: 'Supprimer la note'}))
    o.appendChild(DCreate('button', {class:'note-btn-edit tiny fright', type:'button', text:'📝', title: 'Éditer la note'}))
    o.appendChild(DCreate('DIV', {class:'note-title', text: this.title}))
    o.appendChild(DCreate('DIV', {class:'note-details', text: `${this.details || ""}`}))
    const aut = DCreate('SPAN', {class:'author', text: this.pseudo})
    const dat = DCreate('SPAN', {class:'date', text: `, le ${this.humanDate}`})
    const dad = DCreate('DIV', {class:'note-author-date'})
    dad.appendChild(aut);dad.appendChild(dat)
    o.appendChild(dad)
    if ( this.obj ) {
      this.obj.replaceNode(o)
    } else {
      this.constructor.listing.appendChild(o)
    }
    this.obj = o
    this.observe()
  }

  observe(){
    this.btnEdit.addEventListener('click', this.onEdit.bind(this))
    this.btnSup.addEventListener('click', this.onSup.bind(this))
  }

  onEdit(ev){
    NoteEditor.edit(this)
  }
  onSup(ev){
    if ( !confirm("Voulez-vous vraiment détruire cette note ?") ) return ;
    this.remove()
  }

  // Pour créer ou actualiser la note
  createOrUpdate(){
    this.save()
  }

  // Pour éditer la note
  edit(){ NoteEditor.edit(this) }

  save(){
    if ( ! NoteEditor.areValidData(this.data) ) return ;
    ServerTalk.dial({
        route: "/tools/save_note"
      , data: {script_args: this.data}
      , callback: this.afterSave.bind(this)
    })
  }
  afterSave(retour){
    // console.info("-> afterSave", retour)
    if (retour.ok){
      this.data = retour.note
      // Créer ou actualiser l'objet d'affichage de la note
      this.build()
    } else {
      Flash.error(retour.error)
      console.error(retour)
    }
  }

  remove(){
    ServerTalk.dial({
        route: "/tools/remove_note"
      , data: {script_args: {note_id: this.id}}
      , callback: this.afterRemove.bind(this)
    })
  }
  afterRemove(retour){
    if (retour.ok) {
      this.obj.remove()
    } else {Flash.error(retour.error)}
  }

  defineHumanDate(){
    const d = new Date(this.inserted_at)
    return d.toLocaleDateString()
  }

  get btnEdit(){return this._btnedit || (this._btnedit = DGet('button.note-btn-edit', this.obj))}
  get btnSup(){return this._btnsup || (this._btnsup = DGet('button.note-btn-sup', this.obj))}
}

/**
 * Pour créer/éditer 
 */
class NoteEditor {

  static init(){
    this.btnSave.addEventListener('click', this.save.bind(this))
  }

  /**
   * Appelée par le bouton "Enregistrer la note"
   */
  static save(){
    const newNote = new Blocnotes(this.getData())
    newNote.createOrUpdate()
  }

  /**
   * Fonction appelée pour éditée la note +note+ {Note}
   */
  static edit(note){
    this.setData(note)
  }

  static setData(note){
    this.forEachProp(prop => this.field(prop).value = note[prop])
  }
  static getData(){
    const res = this.forEachProp(prop => {
      console.info("prop = ", prop)
      return this.field(prop).value
    })
    console.info("Récupération des données : ", res)
    return res
  }
  /**
   * Check des données.
   * 
   * @return True si les données sont valides, False dans le case
   * contraire.
   */
  static areValidData(){
    try {
      const title = this.value('title');
      title || raise("Il faut fournir au moins un titre.", this.field('title'))
      const tsid = this.value('task_spec_id')
      tsid  || raise("L'identifiant de la tâche (sa fiche spec) devrait être défini… Quelque chose en va pas…")
    } catch (err) {
      Flash.error(err.message)
      return false
    }
    return true
  }
  /**
   * Pour boucler la méthode +method+ sur chaque propriété.
   * Méthode reçoit en premier argument la propriété {String} et en
   * second argument les données absolues de la propriété.
   * 
   * @return {Object} Une table contenant le résultat pour chaque
   * propriété
   */
  static forEachProp(method){
    const retour = {}
    for (var prop in NOTES_PROPERTIES){
      const res = method.call(this, ...[prop, NOTES_PROPERTIES[prop]])      
      Object.assign(retour, {[prop]: res})
    }
    return retour
  }

  static value(prop){ return NullIfEmpty(this.field(prop).value) }
  static field(prop){ return this.fields[prop] }

  static get btnSave(){return this._btnsave || (this._btnsave = DGet('button.btn-save', this.obj))}
  static get obj(){
    return this._obj || (this._obj = DGet('div#blocnotes-note-form'))
  }
  static get fields(){
    return this._fields || (this._fields = this.defineFields())
  }
  static defineFields(){
    const m = {}
    for (var prop in NOTES_PROPERTIES){
      Object.assign(m, {[prop]: DGet(`#edit_note-${prop}`, this.obj)})
    }
    return m
  }
}

window.Blocnotes = Blocnotes
