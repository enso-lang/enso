'use strict'

//// FindModel ////

var cwd = process.cwd() + '/';
var Enso = require(cwd + "enso.js");

var FindModel;

var file_map = function() {
  var self = this;
  if (self.file_map$ == null) {
    self.file_map$ = Enso.File.load_file_map();
  }
  return self.file_map$;
};

var find_model = function(block, model) {
  var self = this, path;
  path = FindModel.file_map().get$(model);
  if (! path) {
    FindModel.raise(Enso.S("File not found ", model));
  }
  return block(path);
};

FindModel = {
  file_map: file_map,
  find_model: find_model,
};
module.exports = FindModel ;
