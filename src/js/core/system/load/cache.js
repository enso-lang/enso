define([
  "core/schema/tools/dumpjson",
  "core/system/utils/find_model",
  "digest/sha1"
],
function(Dumpjson, FindModel, Sha1) {
  var Cache ;

  Cache = {
    save_cache: function(name, model, out) {
      var self = this; 
      if (out === undefined) out = Cache.find_json(name);
      var res;
      res = Cache.add_metadata(name, model);
      res._set("model", Dumpjson.to_json(model, true));
      return File.open(function(f) {
        return f.write(JSON.pretty_generate(res, new EnsoHash ({ allow_nan: true, max_nesting: false })));
      }, out, "w+");
    },

    load_cache: function(name, factory, input) {
      var self = this; 
      if (input === undefined) input = Cache.find_json(name);
      var type, json, res;
      type = name.split(".")._get(- 1);
      json = System.readJSON(input);
      res = Dumpjson.from_json(factory, json._get("model"));
      res.factory().file_path()._set(0, json._get("source"));
      json._get("depends").each(function(dep) {
        return res.factory().file_path().push(dep._get("filename"));
      });
      return res;
    },

    check_dep: function(name) {
      var self = this; 
      var path, json;
      try {
        path = Cache.find_json(name);
        json = System.readJSON(path);
        return Cache.check_file(json) && json._get("depends").all_P(function(e) {
          return Cache.check_file(e);
        });
      } catch (e) {
        return false;
      }
    },

    clean: function(name) {
      var self = this; 
      if (name === undefined) name = null;
      var cache_path;
      cache_path = "cache/";
      if (name == null) {
        if (File.exists_P(S(cache_path, "*"))) {
          return File.delete(S(cache_path, "*"));
        }
      } else if (File.exists_P(Cache.find_json(name))) {
        return File.delete(Cache.find_json(name));
      }
    },

    find_json: function(name) {
      var self = this; 
      var cache_path;
      cache_path = "cache/";
      if (["schema.schema", "schema.grammar", "grammar.schema", "grammar.grammar"].include_P(name)) {
        return S("core/system/boot/", name.gsub(".", "_"), ".json");
      } else {
        if (! File.exists_P(cache_path)) {
          Dir.mkdir(cache_path);
        }
        return S(cache_path, name.gsub(".", "_"), ".json");
      }
    },

    check_file: function(element) {
      var self = this; 
      var path, checksum;
      path = element._get("source");
      checksum = element._get("checksum");
      try {
        return Cache.readHash(path) == checksum;
      } catch (DUMMY) {
        return false;
      }
    },

    get_meta: function(name) {
      var self = this; 
      var e;
      e = new EnsoHash ({ filename: name });
      FindModel.FindModel.find_model(function(path) {
        e._set("source", path);
        e._set("date", File.ctime(path));
        return e._set("checksum", Cache.readHash(path));
      }, name);
      return e;
    },

    add_metadata: function(name, model) {
      var self = this; 
      var e, type, deps;
      if (name == null) {
        e = new EnsoHash ({ filename: "MetaData" });
      } else {
        e = Cache.get_meta(name);
        type = name.split(".")._get(- 1);
        deps = [];
        deps.push(Cache.get_meta(S(type, ".grammar")));
        model.factory().file_path()._get(Range.new(1, - 1)).each(function(fn) {
          return deps.push(Cache.get_meta(fn.split("/")._get(- 1)));
        });
        e._set("depends", deps);
      }
      return e;
    },

    readHash: function(path) {
      var self = this; 
      var hashfun, fullfilename, readBuf;
      hashfun = Digest.SHA1.new();
      fullfilename = path;
      Cache.open(function(io) {
        while (! io.eof()) {
          readBuf = io.readpartial(50);
          hashfun.update(readBuf);
        }
      }, fullfilename, "r");
      return hashfun.to_s();
    },

  };
  return Cache;
})
