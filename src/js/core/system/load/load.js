'use strict'

//// Load ////

var cwd = process.cwd() + '/';
var Schema = require(cwd + "core/system/library/schema.js");
var MetaSchema = require(cwd + "core/system/boot/meta_schema.js");
var Factory = require(cwd + "core/schema/code/factory.js");
var Parse = require(cwd + "core/grammar/parse/parse.js");
var Union = require(cwd + "core/schema/tools/union.js");
var Cache = require(cwd + "core/system/load/cache.js");
var Schemapath = require(cwd + "core/system/utils/schemapath.js");
var FindModel = require(cwd + "core/system/utils/find_model.js");
var Enso = require(cwd + "enso.js");

var Load;

var load = function(name) {
  var self = this;
  return Load.Loader.load(name);
};

var load_in_place = function(name) {
  var self = this;
  return Load.Loader.load_in_place(name);
};

var Load_text = function(type, factory, source, show = false) {
  var self = this;
  return Load.load_text(type, factory, source, show);
};

class LoaderClass {
  static new(...args) { return new LoaderClass(...args) };

  setup() {
    var self = this, ss, gs;
    self.cache$ = Enso.EMap.new();
    ss = self.boot_from_cache("schema.schema", null);
    ss = self.boot_from_cache("schema.schema", ss);
    self.cache$ .set$("schema.schema", ss);
    gs = self.boot_from_cache("grammar.schema", ss);
    self.cache$ .set$("grammar.schema", gs);
    self.cache$ .set$("grammar.grammar", self.boot_from_cache("grammar.grammar", gs));
    self.cache$ .set$("schema.grammar", self.boot_from_cache("schema.grammar", gs));
    Schemapath.Path.set_factory(Factory.SchemaFactory.new(ss));
    if (false) {
      self.update_json("grammar.grammar");
      self.update_json("schema.grammar");
      self.update_json("schema.schema");
      return self.update_json("grammar.schema");
    }
  };

  boot_from_cache(model, schema) {
    var self = this, path, result;
    path = Cache.find_json(model);
    if (schema == null) {
      return result = MetaSchema.load_path(path);
    } else {
      return result = Cache.load_cache(model, schema, path);
    }
  };

  load(model) {
    var self = this, result, type, schema;
    if (self.cache$ == null) {
      self.setup();
    }
    result = self.cache$.get$(model);
    if (result == null) {
      type = model.split_M(".").get$(1);
      if (Enso.System.is_javascript() || Cache.check_dep(model)) {
        try {
          Enso.puts(Enso.S("## fetching ", model));
          schema = self.load(Enso.S(type, ".schema"));
          result = Cache.load_cache(model, schema);
        } catch (e) {
        }
      }
      if (result == null && ! Enso.System.is_javascript()) {
        Enso.puts(Enso.S("## parsing and caching ", model));
        result = self.parse_with_type(model, type);
        Enso.puts(Enso.S("## caching ", model));
        Cache.save_cache(model, result, false);
        result;
      }
      self.cache$ .set$(model, result);
    }
    if (result == null) {
      self.raise(Enso.S("Model not loaded: ", model));
    }
    return result;
  };

  load_in_place(model, type = null) {
    var self = this;
    self.cache$.delete_M(model);
    return self.cache$ .set$(model, self.load(model, type));
  };

  load_text(type, factory, source, show = false) {
    var self = this, g, s, result;
    g = self.load(Enso.S(type, ".grammar"));
    s = self.load(Enso.S(type, ".schema"));
    result = Parse.load_raw(source, g, s, factory, show);
    return result.finalize();
  };

  parse_with_type(model, type) {
    var self = this, g, s, res;
    g = self.load(Enso.S(type, ".grammar"));
    s = self.load(Enso.S(type, ".schema"));
    return res = self.parse_with_models(model, g, s);
  };

  parse_with_models(model, grammar, schema, encoding = null) {
    var self = this;
    return FindModel.find_model(function(path) {
      return Parse.load_file(path, grammar, schema, encoding);
    }, model);
  };

  update_json(model) {
    var self = this, parts, name, type, other;
    parts = name.split_M(".");
    name = parts.get$(0);
    type = parts.get$(1);
    if (Cache.check_dep(model)) {
      return self.patch_schema_pointers_in_place(self.cache$.get$(model), self.load(Enso.S(type, ".schema")));
    } else {
      self.cache$ .set$(name, self.load_with_models(name, self.load(Enso.S(type, ".grammar")), self.load(Enso.S(type, ".schema"))));
      other = self.cache$.get$(name);
      self.cache$ .set$(name, Union.Copy(Factory.SchemaFactory.new(self.load(Enso.S(type, ".schema"))), other));
      self.cache$.get$(name).factory().set_file_path(other.factory().file_path());
      return Cache.save_cache(name, self.cache$.get$(name), true);
    }
  };

  patch_schema_pointers_in_place(obj, schema) {
    var self = this, all_classes;
    all_classes = Enso.EMap.new();
    Schema.map(function(o) {
      all_classes .set$(o, schema.types().get$(o.schema_class().name()));
      return o;
    }, obj);
    return all_classes.each(function(o, sc) {
      return o.instance_eval(function() {
        return self.define_singleton_value("schema_class", sc);
      });
    });
  };
};

var Loader = LoaderClass.new();

Load = {
  load: load,
  load_in_place: load_in_place,
  Load_text: Load_text,
  LoaderClass: LoaderClass,
  Loader: Loader,
};
module.exports = Load ;
