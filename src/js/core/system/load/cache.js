define([
  "core/schema/tools/dumpjson",
  "core/system/utils/find_model",
  "digest/sha1",
  "fileutils"
],
function(Dumpjson, FindModel, Sha1) {
  var Cache ;

  Cache = {
    save_cache: function(name, model, full) {
      var self = this; 
      if (full === undefined) full = false;
      var out, res;
      out = Cache.find_json(name);
      res = Cache.add_metadata(name, model);
      res._set("model", Dumpjson.to_json(model, full));
      return File.open(function(f) {
        return f.write(JSON.pretty_generate(res, new EnsoHash ({ allow_nan: true, max_nesting: false })));
      }, out, "w+");
    },

    load_cache: function(name, factory, input) {
      var self = this; 
      if (input === undefined) input = Cache.find_json(name);
      var type, json, res;
      type = name.split(".")._get(- 1);
      puts(S("## loading cache for: ", name, " (", input, ")"));
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
        if (File.exists_P(cache_path)) {
          Dir.foreach(function(f) {
            if (f.end_with_P(".json")) {
              return File.delete(S(cache_path, f));
            }
          }, cache_path);
          return true;
        } else {
          return false;
        }
      } else if (["schema.schema", "schema.grammar", "grammar.schema", "grammar.grammar"].include_P(name)) {
        return false;
      } else if (File.exists_P(Cache.find_json(name))) {
        File.delete(Cache.find_json(name));
        return true;
      } else {
        return false;
      }
    },

    find_json: function(name) {
      var self = this; 
      var prefix, cache_path;
      prefix = "";
      if (true) {
        prefix = "../";
      }
      if (["schema.schema", "schema.grammar", "grammar.schema", "grammar.grammar"].include_P(name)) {
        return S(prefix, "core/system/boot/", name.gsub(".", "_"), ".json");
      } else {
        cache_path = S(prefix, "cache/");
        index = name.rindex("/");
        if (index) {
          puts(S("SLASH ", name, " => ", index));
          dir = name._get(Range.new(0, index)).gsub(".", "_");
          if (! File.exists_P(S(cache_path, dir))) {
            puts(S("#### making ", cache_path, dir));
            FileUtils.mkdir_p(S(cache_path, dir));
          }
        }
        puts(S("## loading chache ", cache_path, name.gsub(".", "_"), ".json"));
        return S(cache_path, name.gsub(".", "_"), ".json");
      }
    },

    check_file: function(element) {
      var self = this; 
      var path, checksum;
      if (Digest == null) {
        return true;
      } else {
        path = element._get("source");
        checksum = element._get("checksum");
        try {
          return Cache.readHash(path) == checksum;
        } catch (DUMMY) {
          return false;
        }
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
