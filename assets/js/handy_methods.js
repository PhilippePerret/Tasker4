window.NullIfEmpty = function(value){
  if ( !value ) return null;
  if ( 'string' == typeof value ){
    value = value.trim()
    if ( value == "" ) return null;
    else return value;
  }
  return value
}