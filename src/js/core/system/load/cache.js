'use strict'

//// Cache ////

var cwd = process.cwd() + '/';
var Dumpjson = require(cwd + "core/schema/tools/dumpjson.js");
var FindModel = require(cwd + "core/system/utils/find_model.js");
var Factory = require(cwd + "core/schema/code/factory.js");
var Sha1 = require(cwd + "digest/sha1.js");
var Enso = require(cwd + "enso.js");

var Cache;

var hack_prefix = function() {
  var self = this;
  if (Enso.System.is_javascript()) {
    return "../";
  } else {
    return "";
  }
};

var save_cache = function(name, model, full = false) {
  var self = this, out, res;
  out = Cache.find_json(name);
  res = Cache.add_metadata(name, model);
  res .set$("model", Dumpjson.to_json(model, full));
  return Enso.File.open(function(f) {
    return f.write(JSON.pretty_generate(res, Enso.EMap.new({allow_nan: true, max_nesting: false})));
  }, out, "w+");
};

var load_cache = function(model, schema, path = Cache.find_json(model)) {
  var self = this, factory, json, res;
  factory = Factory.SchemaFactory.new(schema);
  json = Enso.System.readJSON(path);
  res = Dumpjson.from_json(factory, json.get$("model"));
  res.factory().file_path() .set$(0, path);
  json.get$("depends").each(function(dep) {
    return res.factory().file_path().push(dep.get$("filename"));
  });
  return res;
};

var check_dep = function(name) {
  var self = this, path, json;
  try {
    path = Cache.find_json(name);
    json = Enso.System.readJSON(path);
    return Cache.check_file(json) && json.get$("depends").all_P(function(e) {
      return Cache.check_file(e);
    });
  } catch (e) {
    return false;
  }
};

var clean = function(name = null) {
  var self = this, cache_path;
  cache_path = "cache/";
  if (name == null) {
    if (Enso.File.exists_P(cache_path)) {
      Dir.foreach(function(f) {
        if (f.end_with_P(".json")) {
          return Enso.File.delete_M(Enso.S(cache_path, f));
        }
      }, cache_path);
      return true;
    } else {
      return false;
    }
  } else if (["schema.schema", "schema.grammar", "grammar.schema", "grammar.grammar"].include_P(name)) {
    return false;
  } else if (Enso.File.exists_P(Cache.find_json(name))) {
    Enso.File.delete_M(Cache.find_json(name));
    return true;
  } else {
    return false;
  }
};

var find_json = function(name) {
  var self = this, cache_path;
  if (["schema.schema", "schema.grammar", "grammar.schema", "grammar.grammar"].include_P(name)) {
    return Enso.S(Cache.hack_prefix(), "core/system/boot/", name, ".json");
  } else {
    cache_path = Enso.S(Cache.hack_prefix(), "cache/");
    return Enso.S(cache_path, name, ".json");
  }
};

var check_file = function(element) {
  var self = this, path, checksum;
  if (Digest == null) {
    return true;
  } else {
    path = element.get$("source");
    checksum = element.get$("checksum");
    try {
      return Cache.readHash(path) == checksum;
    } catch (DUMMY) {
      return false;
    }
  }
};

var get_meta = function(name) {
  var self = this, e;
  e = Enso.EMap.new({filename: name});
  try {
    FindModel.find_model(function(path) {
      e .set$("source", path);
      e .set$("date", Enso.File.ctime(path));
      return e .set$("checksum", Cache.readHash(path));
    }, name);
  } catch (DUMMY) {
    e .set$("source", "SYNTHETIC");
    e .set$("date", Time.new());
  }
  return e;
};

var add_metadata = function(name, model) {
  var self = this, e, type, deps;
  if (name == null) {
    e = Enso.EMap.new({filename: "MetaData"});
  } else {
    e = Cache.get_meta(name);
    type = name.split_M(".").get$(- 1);
    deps = [];
    deps.push(Cache.get_meta(Enso.S(type, ".grammar")));
    if (model.factory().file_path().size_M() > 0) {
      model.factory().file_path().get$(Range.new(1, - 1)).each(function(fn) {
        return deps.push(Cache.get_meta(fn.split_M("/").get$(- 1)));
      });
    }
    e .set$("depends", deps);
  }
  return e;
};

var readHash = function(path) {
  var self = this, hashfun, fullfilename, readBuf;
  hashfun = Digest.SHA1.new();
  fullfilename = path;
  Cache.open(function(io) {
    while (! io.eof()) {
      readBuf = io.readpartial(50);
      hashfun.update(readBuf);
    }
  }, fullfilename, "r");
  return hashfun.to_s();
};

Cache = {
  hack_prefix: hack_prefix,
  save_cache: save_cache,
  load_cache: load_cache,
  check_dep: check_dep,
  clean: clean,
  find_json: find_json,
  check_file: check_file,
  get_meta: get_meta,
  add_metadata: add_metadata,
  readHash: readHash,
};
module.exports = Cache ;
