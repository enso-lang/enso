define(["core/schema/tools/dumpjson", "core/system/utils/find_model", "digest/sha1"], (function (Dumpjson, FindModel, Sha1) {
  var Cache;
  (Cache = {
    save_cache: (function (name, model, full) {
      var self = this;
      (full = (((typeof full) !== "undefined") ? full : false));
      var res, out;
      (out = self.find_json(name));
      (res = self.add_metadata(name, model));
      res._set("model", Dumpjson.to_json(model, full));
      return File.open((function (f) {
        return f.write(JSON.pretty_generate(res, (new EnsoHash({
          allow_nan: true,
          max_nesting: false
        }))));
      }), out, "w+");
    }),
    readHash: (function (path) {
      var self = this;
      var hashfun, fullfilename;
      (hashfun = Digest.SHA1.new());
      (fullfilename = path);
      self.open((function (io) {
        var readBuf;
        while ((!io.eof())) {
          (readBuf = io.readpartial(50));
          hashfun.update(readBuf);
        }
      }), fullfilename, "r");
      return hashfun.to_s();
    }),
    add_metadata: (function (name, model) {
      var self = this;
      var deps, e, type;
      if ((name == null)) { 
        (e = (new EnsoHash({
          filename: "MetaData"
        }))); 
      } 
      else {
             (e = self.get_meta(name));
             (type = name.split(".")._get((-1)));
             (deps = []);
             deps.push(self.get_meta(S("", type, ".grammar")));
             model.factory().file_path()._get(Range.new(1, (-1))).each((function (fn) {
               return deps.push(self.get_meta(fn.split("/")._get((-1))));
             }));
             e._set("depends", deps);
           }
      return e;
    }),
    hack_prefix: (function () {
      var self = this;
      if (true) { 
        return "../"; 
      }
      else { 
        return "";
      }
    }),
    check_file: (function (element) {
      var self = this;
      var checksum, path;
      if ((Digest == null)) { 
        return true; 
      } 
      else {
             (path = element._get("source"));
             (checksum = element._get("checksum"));
             try {return (self.readHash(path) == checksum);
                  
             }
             catch (caught$3086) {
               
                 return false;
             }
           }
    }),
    check_dep: (function (name) {
      var self = this;
      var path, json;
      try {(path = self.find_json(name));
           (json = System.readJSON(path));
           return (self.check_file(json) && json._get("depends").all_P((function (e) {
        return self.check_file(e);
      })));
           
      }
      catch (caught$1097) {
        
          if ((caught$1097 instanceof self.Errno().ENOENT)) { 
            return (function (e) {
              false;
            })(caught$1097); 
          }
          else { 
            ;
          }
      }
    }),
    clean: (function (name) {
      var self = this;
      (name = (((typeof name) !== "undefined") ? name : null));
      var cache_path;
      (cache_path = "cache/");
      if ((name == null)) { 
        if (File.exists_P(S("", cache_path, ""))) {
          self.Dir().foreach((function (f) {
            if (f.end_with_P(".json")) {
              return File.delete(S("", cache_path, "", f, ""));
            }
          }), S("", cache_path, ""));
          return true;
        }
        else {
          return false;
        } 
      }
      else { 
        if (["schema.schema", "schema.grammar", "grammar.schema", "grammar.grammar"].include_P(name)) { 
          return false; 
        }
        else { 
          if (File.exists_P(self.find_json(name))) {
            File.delete(self.find_json(name));
            return true;
          }
          else {
            return false;
          }
        }
      }
    }),
    load_cache: (function (name, factory, input, model) {
      var self = this;
      (input = (((typeof input) !== "undefined") ? input : null));
      (model = (((typeof model) !== "undefined") ? model : "model"));
      var res, json, type;
      if ((input == null)) {
        (input = self.find_json(name));
      }
      (type = name.split(".")._get((-1)));
      puts(S("## loading cache for: ", name, " (", input, ")"));
      (json = System.readJSON(input));
      (res = Dumpjson.from_json(factory, json._get(model)));
      res.factory().file_path()._set(0, (self.hack_prefix() + json._get("source")));
      json._get("depends").each((function (dep) {
        return res.factory().file_path().push(dep._get("filename"));
      }));
      return res;
    }),
    get_meta: (function (name) {
      var self = this;
      var e;
      (e = (new EnsoHash({
        filename: name
      })));
      try {return FindModel.FindModel.find_model((function (path) {
        e._set("source", path);
        e._set("date", File.ctime(path));
        return e._set("checksum", self.readHash(path));
      }), name);
           
      }
      catch (caught$3227) {
        
          e._set("source", "SYNTHETIC");
          return e._set("date", self.Time().new());
      }
    }),
    find_json: (function (name) {
      var self = this;
      var cache_path, dir, index;
      if (["schema.schema", "schema.grammar", "grammar.schema", "grammar.grammar"].include_P(name)) { 
        return S("", self.hack_prefix(), "core/system/boot/", name.gsub(".", "_"), ".json"); 
      } 
      else {
             (cache_path = S("", self.hack_prefix(), "cache/"));
             (index = name.rindex("/"));
             if ((index && (index >= 0))) {
               puts(S("SLASH ", name, " => ", index, ""));
               (dir = name._get(Range.new(0, index)).gsub(".", "_"));
               if ((!File.exists_P(S("", cache_path, "", dir, "")))) {
                 puts(S("#### making ", cache_path, "", dir, ""));
                 FileUtils.mkdir_p(S("", cache_path, "", dir, ""));
               }
             }
             puts(S("## loading chache ", cache_path, "", name.gsub(".", "_"), ".json"));
             return S("", cache_path, "", name.gsub(".", "_"), ".json");
           }
    })
  });
  return Cache;
}));