define(["core/system/library/schema", "core/system/boot/meta_schema", "core/schema/code/factory", "core/grammar/parse/parse", "core/schema/tools/union", "core/schema/tools/rename", "core/system/load/cache", "core/system/utils/paths", "core/system/utils/find_model"], (function (Schema, MetaSchema, Factory, Parse, Union, Rename, Cache, Paths, FindModel) {
  var Load;
  var Loader;
  var LoaderClass = MakeClass("LoaderClass", null, [], (function () {
  }), (function (super$) {
    (this.load = (function (name, type) {
      var self = this;
      (type = (((typeof type) !== "undefined") ? type : null));
      if ((self.$.cache == null)) {
        self.setup();
      }
      if (self.$.cache._get(name)) { 
        return self.$.cache._get(name); 
      }
      else { 
        return self.load_C(name, type);
      }
    }));
    (this.load_C = (function (name, type) {
      var self = this;
      (type = (((typeof type) !== "undefined") ? type : null));
      return self.$.cache._set(name, self._load(name, type));
    }));
    (this.load_text = (function (type, factory, source, show) {
      var self = this;
      (show = (((typeof show) !== "undefined") ? show : false));
      var g, s, result;
      (g = self.load(S("", type, ".grammar")));
      (s = self.load(S("", type, ".schema")));
      (result = Parse.load_raw(source, g, s, factory, show));
      return result.finalize();
    }));
    (this._load = (function (name, type) {
      var self = this;
      (type = (((typeof type) !== "undefined") ? type : null));
      var res;
      (type = (type || name.split(".")._get((-1))));
      if (((Parse == null) || Cache.check_dep(name))) {
        System.stderr().push(S("## fetching ", name, "...\n"));
        return Cache.load_cache(name, Factory.new(self.load(S("", type, ".schema"))));
      } else {
        (res = self.parse_with_type(name, type));
        System.stderr().push(S("## caching ", name, "...\n"));
        Cache.save_cache(name, res, false);
        return res;
      }
    }));
    (this.parse_with_type = (function (name, type) {
      var self = this;
      var res, g, s;
      (g = self.load(S("", type, ".grammar")));
      (s = self.load(S("", type, ".schema")));
      return (res = self.load_with_models(name, g, s));
    }));
    (this.setup = (function () {
      var self = this;
      var ss, gs;
      (self.$.cache = (new EnsoHash({
        
      })));
      self.$.cache._set("schema.schema", (ss = self.load_with_models("schema_schema.json", null, null)));
      self.$.cache._set("grammar.schema", (gs = self.load_with_models("grammar_schema.json", null, ss)));
      self.$.cache._set("grammar.grammar", self.load_with_models("grammar_grammar.json", null, gs));
      self.$.cache._set("schema.grammar", self.load_with_models("schema_grammar.json", null, gs));
      Paths.Path.set_factory(Factory.new(ss));
      if (false) {
        self.update_json("grammar.grammar");
        self.update_json("schema.grammar");
        self.update_json("schema.schema");
        return self.update_json("grammar.schema");
      }
    }));
    (this.update_json = (function (name) {
      var self = this;
      var parts, model, new_V, type;
      (parts = name.split("."));
      (model = parts._get(0));
      (type = parts._get(1));
      if (Cache.check_dep(name)) { 
        return self.patch_schema_pointers_C(self.$.cache._get(name), self.load(S("", type, ".schema"))); 
      } 
      else {
             self.$.cache._set(name, self.load_with_models(name, self.load(S("", type, ".grammar")), self.load(S("", type, ".schema"))));
             (new_V = self.$.cache._get(name));
             self.$.cache._set(name, Union.Copy(Factory.new(self.load(S("", type, ".schema"))), new_V));
             self.$.cache._get(name).factory().set_file_path(new_V.factory().file_path());
             return Cache.save_cache(name, self.$.cache._get(name), true);
           }
    }));
    (this.patch_schema_pointers_C = (function (obj, schema) {
      var self = this;
      var all_classes;
      (all_classes = (new EnsoHash({
        
      })));
      Schema.map((function (o) {
        all_classes._set(o, schema.types()._get(o.schema_class().name()));
        return o;
      }), obj);
      return all_classes.each((function (o, sc) {
        return o.instance_eval((function () {
          return self.define_singleton_value("schema_class", sc);
        }));
      }));
    }));
    (this.load_with_models = (function (name, grammar, schema, encoding) {
      var self = this;
      (encoding = (((typeof encoding) !== "undefined") ? encoding : null));
      return FindModel.FindModel.find_model((function (path) {
        return self.load_path(path, grammar, schema, encoding);
      }), name);
    }));
    (this.load_path = (function (path, grammar, schema, encoding) {
      var self = this;
      (encoding = (((typeof encoding) !== "undefined") ? encoding : null));
      var name, type, result;
      if (path.end_with_P(".json")) { 
        if ((schema == null)) {
          System.stderr().push(S("## booting ", path, "...\n"));
          (result = MetaSchema.load_path(path));
        } else {
          System.stderr().push(S("## fetching ", path, "...\n"));
          (name = path.split("/")._get((-1)).split(".")._get(0).gsub("_", "."));
          (type = name.split(".")._get((-1)));
          (result = Cache.load_cache(name, Factory.new(self.load(S("", type, ".schema")))));
        } 
      }
      else { 
        if ((Parse == null)) {
          System.stderr().push(S("## fetching! ", path, "...\n"));
          (name = path.split("/")._get((-1)));
          (type = name.split(".")._get((-1)));
          (result = Cache.load_cache(name, Factory.new(self.load(S("", type, ".schema")))));
        } else {
          System.stderr().push(S("## loading ", path, "...\n"));
          (result = Parse.load_file(path, grammar, schema, encoding));
        }
      }
      return result;
    }));
  }));
  undefined;
  (Load = {
    LoaderClass: LoaderClass,
    Loader: (Loader = (Loader || LoaderClass.new())),
    Load_text: (function (type, factory, source, show) {
      var self = this;
      (show = (((typeof show) !== "undefined") ? show : false));
      return Load.load_text(type, factory, source, show);
    }),
    load: (function (name) {
      var self = this;
      return Load.Loader.load(name);
    }),
    load_with_models: (function (name, grammar, schema, encoding) {
      var self = this;
      (encoding = (((typeof encoding) !== "undefined") ? encoding : null));
      return Load.Loader.load_with_models(name, grammar, schema, encoding);
    }),
    load_C: (function (name) {
      var self = this;
      return Load.Loader.load_C(name);
    })
  });
  return Load;
}));