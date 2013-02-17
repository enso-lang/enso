define([
  "core/system/library/schema",
  "core/system/boot/meta_schema",
  "core/grammar/parse/parse",
  "core/schema/tools/union",
  "core/schema/tools/rename",
  "core/system/load/cache"
],
function(Schema, MetaSchema, Parse, Union, Rename, Cache) {

  var Load ;

  var LoaderClass = MakeClass( {
    GRAMMAR_GRAMMAR: "grammar.grammar",

    SCHEMA_SCHEMA: "schema.schema",

    SCHEMA_GRAMMAR: "schema.grammar",

    GRAMMAR_SCHEMA: "grammar.schema",

    load: function(name, type) {
      var self = this; 
      if (type === undefined) type = null;
      var GRAMMAR_GRAMMAR, SCHEMA_SCHEMA, SCHEMA_GRAMMAR, GRAMMAR_SCHEMA;
      var super$ = this.super$.load;
      if (self.$.cache == null) {
        self.setup();
      }
      if (self.$.cache._get(name)) {
        return self.$.cache._get(name);
      } else {
        return self.load_in_place(name, type);
      }
    },

    load_in_place: function(name, type) {
      var self = this; 
      if (type === undefined) type = null;
      var super$ = this.super$.load_in_place;
      return self.$.cache ._set( name , self._load(name, type) );
    },

    load_text: function(type, factory, source, show) {
      var self = this; 
      if (show === undefined) show = false;
      var g, s, result;
      var super$ = this.super$.load_text;
      g = self.load(S(type, ".grammar"));
      s = self.load(S(type, ".schema"));
      result = Parse.load_raw(source, g, s, factory, show);
      return result.finalize();
    },

    load_cache: function(name, obj) {
      var self = this; 
      var super$ = this.super$.load_cache;
      System.stderr().push(S("## caching ", name, "...\\n"));
      return self.$.cache ._set( name , obj );
    },

    _load: function(name, type) {
      var self = this; 
      var filename, parts, model, type, g, s, res;
      var super$ = this.super$._load;
      if (Cache.check_dep(name)) {
        System.stderr().push(S("## fetching ", name, "...\\n"));
        return Cache.load_cache(name);
      } else {
        filename = name.split("/")._get(- 1);
        if (type == null) {
          parts = filename.split(".");
          model = parts._get(0);
          type = parts._get(1);
        }
        g = self.load(S(type, ".grammar"));
        s = self.load(S(type, ".schema"));
        res = self.load_with_models(name, g, s);
        System.stderr().push(S("## caching ", name, "...\\n"));
        Cache.save_cache(filename, res);
        return res;
      }
    },

    setup: function() {
      var self = this; 
      var ss, gs, gg, sg;
      var super$ = this.super$.setup;
      self.$.cache = new EnsoHash ( { } );
      System.stderr().push("Initializing...\\n");
      self.$.cache ._set( SCHEMA_SCHEMA , ss = self.load_with_models("schema_schema.json", null, null) );
      self.$.cache ._set( GRAMMAR_SCHEMA , gs = self.load_with_models("grammar_schema.json", null, ss) );
      self.$.cache ._set( GRAMMAR_GRAMMAR , gg = self.load_with_models("grammar_grammar.json", null, gs) );
      self.$.cache ._set( SCHEMA_GRAMMAR , sg = self.load_with_models("schema_grammar.json", null, gs) );
      self.$.cache ._set( SCHEMA_SCHEMA , ss = self.update_xml("schema.schema") );
      self.$.cache ._set( GRAMMAR_SCHEMA , gs = self.update_xml("grammar.schema") );
      self.$.cache ._set( GRAMMAR_GRAMMAR , gg = self.update_xml("grammar.grammar") );
      return self.$.cache ._set( SCHEMA_GRAMMAR , sg = self.update_xml("schema.grammar") );
    },

    update_xml: function(name) {
      var self = this; 
      var parts, model, type, res;
      var super$ = this.super$.update_xml;
      if (Cache.check_dep(name)) {
        return self.$.cache._get(name);
      } else {
        if (type == null) {
          parts = name.split(".");
          model = parts._get(0);
          type = parts._get(1);
        }
        res = self.load_with_models(name, self.load(S(type, ".grammar")), self.load(S(type, ".schema")));
        self.patch_schema_pointers_in_place(res, self.load(S(type, ".schema")));
        System.stderr().push(S("## caching ", name, "...\\n"));
        Cache.save_cache(name, res);
        return res;
      }
    },

    patch_schema_pointers_in_place: function(obj, schema) {
      var self = this; 
      var all_classes;
      var super$ = this.super$.patch_schema_pointers_in_place;
      all_classes = [];
      Schema.map(function(o) {
        all_classes.push(o);
        return o;
      }, obj);
      return all_classes.each(function(o) {
        return o.instance_eval(function() {
          self.$.schema_class = schema.types()._get(self.$.schema_class.name());
          return self.$.factory.instance_eval(function() {
            return self.$.schema = schema;
          });
        });
      });
    },

    load_with_models: function(name, grammar, schema, encoding) {
      var self = this; 
      if (encoding === undefined) encoding = null;
      var super$ = this.super$.load_with_models;
      return self.find_model(function(path) {
        return self.load_path(path, grammar, schema, encoding);
      }, name);
    },

    load_path: function(path, grammar, schema, encoding) {
      var self = this; 
      if (encoding === undefined) encoding = null;
      var result, name, header, str, a, fnames;
      var super$ = this.super$.load_path;
      if (path.end_with_P(".xml") || path.end_with_P(".json")) {
        if (schema == null) {
          System.stderr().push(S("## booting ", path, "...\\n"));
          result = Boot.load_path(path);
          result.factory().file_path() ._set( 0 , path );
        } else {
          name = path.split("/")._get(- 1).split(".")._get(0);
          name ._set( name.rindex("_") , "." );
          result = Cache.load_cache(name);
        }
      } else {
        try {
          header = File.open(function(x) {
            return x.readline();
          }, path);
        } catch ( err ) {
          self.puts(S("Unable to open file ", path));
          self.raise(err);
        }
        if (header == "#ruby") {
          System.stderr().push(S("## building ", path, "...\\n"));
          str = File.read(path);
          result = self.instance_eval(str);
          result.factory().file_path() ._set( 0 , path );
          a = str.split("\\\"").map(function(x) {
            return x.split("\\'");
          }).flatten();
          fnames = a.values_at .call_rest_args$(a, a.each_index().select(function(i) {
            return i.odd_P();
          }) );
          fnames.each(function(fn) {
            return result.factory().file_path().push(fn);
          });
        } else {
          System.stderr().push(S("## loading ", path, "...\\n"));
          result = Parse.load_file(path, grammar, schema, encoding);
        }
      }
      return result;
    },

    find_model: function(block, name) {
      var self = this; 
      var path;
      var super$ = this.super$.find_model;
      if (File.exists_P(name)) {
        return block.call(name);
      } else {
        path = Dir._get("**/*.*").find(function(p) {
          return File.basename(p) == name;
        });
        if (path == null) {
          return null;
        } else {
          if (! path) {
            self.raise(EOFError, S("File not found ", name));
          }
          return block.call(path);
        }
      }
    }
  });

  Load = {
    load: function(name) {
      return Loader.load(name);
    } ,

    Load_text: function(type, factory, source, show) {
      if (show === undefined) show = false;
      return Load.load_text(type, factory, source, show);
    } ,

    LoaderClass: LoaderClass,
    Loader: LoaderClass.new() ,

  };
  return Load;
})
