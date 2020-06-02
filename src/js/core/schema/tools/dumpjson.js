'use strict'

//// Dumpjson ////

var cwd = process.cwd() + '/';
var Schema = require(cwd + "core/system/library/schema.js");
var MetaSchema = require(cwd + "core/system/boot/meta_schema.js");
var Json = require(cwd + "json.js");
var Enso = require(cwd + "enso.js");

var Dumpjson;

var to_json = function(json, do_all = false) {
  var self = this, e, name, val, ef;
  if (json == null) {
    return null;
  } else {
    e = Enso.EMap.new();
    e .set$("class", json.schema_class().name());
    json.schema_class().fields().each(function(f) {
      name = f.name();
      val = json.get$(name);
      if (do_all || val) {
        if (Enso.System.test_type(f.type(), "Primitive")) {
          return e .set$(Enso.S(name, "="), val);
        } else if (f.many()) {
          if (f.type().key()) {
            name = name + "#";
          }
          ef = [];
          if (f.traversal()) {
            val.each(function(fobj) {
              return ef.push(Dumpjson.to_json(fobj, do_all));
            });
          } else {
            val.each(function(fobj) {
              return ef.push(Dumpjson.fixup_path(fobj));
            });
          }
          if (do_all || ef.size_M() > 0) {
            return e .set$(name, ef);
          }
        } else if (do_all || ! (val == null)) {
          if (f.traversal()) {
            return e .set$(name, val && Dumpjson.to_json(val, do_all));
          } else {
            return e .set$(name, val && Dumpjson.fixup_path(val));
          }
        }
      }
    });
    return e;
  }
};

var fixup_path = function(obj) {
  var self = this, path;
  path = obj._path().to_s();
  puts(Enso.S("PATH ", path));
  if (path == "root") {
    return path = "";
  } else {
    return path = path.slice_M(5, 999);
  }
};

var from_json = function(factory, text) {
  var self = this;
  return FromJSON.new(factory).decode(text);
};

class Fixup {
  static new(...args) { return new Fixup(...args) };

  constructor(obj, field, spec) {
    var self = this;
    self.obj$ = obj;
    self.field$ = field;
    self.spec$ = spec;
  };

  apply(root) {
    var self = this, collection;
    if (! self.field$.many()) {
      return self.obj$ .set$(self.field$.name(), MetaSchema.path_eval(self.spec$, root));
    } else {
      collection = self.obj$.get$(self.field$.name());
      return self.spec$.each(function(path) {
        return collection.push(MetaSchema.path_eval(path, root));
      });
    }
  };
};

class FromJSON {
  static new(...args) { return new FromJSON(...args) };

  constructor(factory) {
    var self = this;
    self.factory$ = factory;
  };

  decode(json) {
    var self = this, res;
    self.fixups$ = [];
    res = self.from_json(json);
    self.fixups$.each(function(fix) {
      return fix.apply(res);
    });
    return res;
  };

  from_json(json) {
    var self = this, obj, val, fname;
    if (json == null) {
      return null;
    } else {
      obj = self.factory$.get$(json.get$("class"));
      obj.schema_class().fields().each(function(f) {
        if (Enso.System.test_type(f.type(), "Primitive")) {
          val = json.get$(Enso.S(f.name(), "="));
          if (! (val == null)) {
            return obj .set$(f.name(), val);
          }
        } else if (! f.many()) {
          if (json.get$(f.name()) == null) {
            return obj .set$(f.name(), null);
          } else if (f.traversal()) {
            return obj .set$(f.name(), self.from_json(json.get$(f.name())));
          } else {
            return self.fixups$.push(Fixup.new(obj, f, json.get$(f.name())));
          }
        } else {
          fname = f.type().key()
            ? Enso.S(f.name(), "#")
            : f.name();
          if (! (json.get$(fname) == null)) {
            if (f.traversal()) {
              return json.get$(fname).each(function(o) {
                return obj.get$(f.name()).push(self.from_json(o));
              });
            } else {
              return self.fixups$.push(Fixup.new(obj, f, json.get$(fname)));
            }
          }
        }
      });
      return obj;
    }
  };
};

Dumpjson = {
  to_json: to_json,
  fixup_path: fixup_path,
  from_json: from_json,
  Fixup: Fixup,
  FromJSON: FromJSON,
};
module.exports = Dumpjson ;
