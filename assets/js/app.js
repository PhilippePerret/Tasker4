// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//
window.LANG = navigator.language.slice(0,2);
const path_locales = `./locales/locales-${LANG}.js`;

import "./locales.js";
import "./handy_methods.js";
import "./server_talk.js";
import "./flash.js";
import "./cboxier.js";
import "./horloge.js";
import "./scripts_data.js";
import "./ui_masker.js";
import "./ui.js";
import "./locales/locales-fr.js";

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html";
