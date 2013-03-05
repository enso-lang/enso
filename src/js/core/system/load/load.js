define([
  "core/system/library/schema",
  "core/system/boot/meta_schema",
  "core/schema/code/factory",
  "core/grammar/parse/parse",
  "core/schema/tools/union",
  "core/schema/tools/rename",
  "core/system/load/cache",
  "core/system/utils/paths",
  "core/system/utils/find_model"
],
function(Schema, MetaSchema, Factory, Parse, Union, Rename, Cache, Paths, FindModel) {
  var Load ;

  var LoaderClass = MakeClass("LoaderClass", null, [],
    function() {
    },
    function(super$) {
      this.load = function(name, type) {
        var self = this; 
        if (type === undefined) type = null;
        if (self.$.cache == null) {
          self.setup();
        }
        if (self.$.cache._get(name)) {
          return self.$.cache._get(name);
        } else {
          return self.load_in_place(name, type);
        }
      };

      this.load_in_place = function(name, type) {
        var self = this; 
        if (type === undefined) type = null;
        return self.$.cache._set(name, self._load(name, type));
      };

      this.load_text = function(type, factory, source, show) {
        var self = this; 
        if (show === undefined) show = false;
        var g, s, result;
        g = self.load(S(type, ".grammar"));
        s = self.load(S(type, ".schema"));
        result = Parse.load_raw(source, g, s, factory, show);
        return result.finalize();
      };

      this.load_cache = function(name, obj) {
        var self = this; 
        System.stderr().push(S("## caching ", name, "...\n"));
        return self.$.cache._set(name, obj);
      };

      this._load = function(name, type) {
        var self = this; 
        var g, s, res;
        type = type || name.split(".")._get(- 1);
        if (Cache.check_dep(name)) {
          System.stderr().push(S("## fetching ", name, "...\n"));
          return Cache.load_cache(name, Factory.new(self.load(S(type, ".schema"))));
        } else {
          g = self.load(S(type, ".grammar"));
          s = self.load(S(type, ".schema"));
          res = self.load_with_models(name, g, s);
          System.stderr().push(S("## caching ", name, "...\n"));
          Cache.save_cache(name, res);
          return res;
        }
      };

      this.setup = function() {
        var self = this; 
        var ss, gs;
        self.$.cache = new EnsoHash ({ });
        System.stderr().push("Initializing...\n");
        self.$.cache._set("schema.schema", ss = self.load_with_models("schema_schema.json", null, null));
        self.$.cache._set("grammar.schema", gs = self.load_with_models("grammar_schema.json", null, ss));
        self.$.cache._set("grammar.grammar", self.load_with_models("grammar_grammar.json", null, gs));
        self.$.cache._set("schema.grammar", self.load_with_models("schema_grammar.json", null, gs));
        return Paths.Path.set_factory(Factory.new(ss));
      };

      this.update_xml = function(name) {
        var self = this; 
        var parts, model, type, res;
        if (Cache.check_dep(name)) {
          return self.$.cache._get(name);
        } else {
          parts = name.split(".");
          model = parts._get(0);
          type = parts._get(1);
          res = self.load_with_models(name, self.load(S(type, ".grammar")), self.load(S(type, ".schema")));
          self.patch_schema_pointers_in_place(res, self.load(S(type, ".schema")));
          System.stderr().push(S("## caching ", name, "...\n"));
          Cache.save_cache(name, res);
          return res;
        }
      };

      this.patch_schema_pointers_in_place = function(obj, schema) {
        var self = this; 
        var all_classes, sc;
        all_classes = [];
        Schema.map(function(o) {
          all_classes.push(o);
          return o;
        }, obj);
        return all_classes.each(function(o) {
          return o.instance_eval(function() {
            sc = schema.types()._get(o.schema_class().name());
            self.define_singleton_value("schema_class", sc);
            return self.$.factory.instance_eval(function() {
              return self.$.schema = schema;
            });
          });
        });
      };

      this.load_with_models = function(name, grammar, schema, encoding) {
        var self = this; 
        if (encoding === undefined) encoding = null;
        return FindModel.FindModel.find_model(function(path) {
          return self.load_path(path, grammar, schema, encoding);
        }, name);
      };

      this.load_path = function(path, grammar, schema, encoding) {
        var self = this; 
        if (encoding === undefined) encoding = null;
        var result, name, type, header, str, a, fnames;
        if (path.end_with_P(".json")) {
          if (schema == null) {
            System.stderr().push(S("## booting ", path, "...\n"));
            result = MetaSchema.load_path(path);
            result.factory().file_path()._set(0, path);
          } else {
            System.stderr().push(S("## fetching ", path, "...\n"));
            name = path.split("/")._get(- 1).split(".")._get(0).gsub("_", ".");
            type = name.split(".")._get(- 1);
            result = Cache.load_cache(name, Factory.new(self.load(S(type, ".schema"))));
          }
        } else {
          try {
            header = File.open(function(x) {
              return x.readline();
            }, path);
          } catch (err) {
            System.stderr().push(S("Unable to open file ", path, "\n"));
            self.raise(err);
          }
          if (header == "#ruby") {
            System.stderr().push(S("## building ", path, "...\n"));
            str = File.read(path);
            result = self.instance_eval(str);
            result.factory().file_path()._set(0, path);
            a = str.split("\"").map(function(x) {
              return x.split("'");
            }).flatten();
            fnames = a.values_at.apply(a, [].concat(a.each_index().select(function(i) {
              return i.odd_P();
            })));
            fnames.each(function(fn) {
              return result.factory().file_path().push(fn);
            });
          } else {
            System.stderr().push(S("## loading ", path, "...\n"));
            result = Parse.load_file(path, grammar, schema, encoding);
          }
        }
        return result;
      };
    });

  Load = {
    load: function(name) {
      var self = this; 
      var Loader;
      return Load.Loader.load(name);
    },

    Load_text: function(type, factory, source, show) {
      var self = this; 
      if (show === undefined) show = false;
      return Load.load_text(type, factory, source, show);
    },

    LoaderClass: LoaderClass,
    Loader: LoaderClass.new(),

  };
  return Load;
})
