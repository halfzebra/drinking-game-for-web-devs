require('./main.css');
var nounList = require('./noun-list.json');
var Elm = require('./Main.elm');

var root = document.getElementById('root');

Elm.Main.embed(root, nounList);