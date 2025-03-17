window.NullIfEmpty = function(value){
  if ( !value ) return null;
  if ( 'string' == typeof value ){
    value = value.trim()
    if ( value == "" ) return null;
    else return value;
  }
  return value
}

window.raise = function(message, domField) {
  if ( domField ) {
    domField.focus()
    domField.select()
  }
  Flash.error(message)
  throw null
}

window.stopEvent = function(ev){
  ev.stopPropagation();
  ev.preventDefault();
  return false
}
