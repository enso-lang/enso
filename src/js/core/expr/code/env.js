define([
],
function() {

  var Env ;
  var BaseEnv = MakeMixin({
    set_in_place: function(block, key) {
      var self = this; 
      var super$ = this.super$.set_in_place;
      return self ._set( key , block.call(self._get(key)) );
    },

    set: function(block, key) {
      var self = this; 
      var res;
      var super$ = this.super$.set;
      res = self.clone();
      res.set_in_place(key, block);
      return res;
    },

    set_parent: function(env) {
      var self = this; 
      var super$ = this.super$.set_parent;
      self.$.parent = env;
      return self;
    },

    set_grandparent: function(env) {
      var self = this; 
      var super$ = this.super$.set_grandparent;
      if (self.$.parent == null || self.$.parent == new EnsoHash ( { } )) {
        return self.set_parent(env);
      } else {
        return self.$.parent.set_grandparent(env);
      }
    },

    add: function(env) {
      var self = this; 
      var super$ = this.super$.add;
      self.set_parent(env);
      return self;
    },

    to_s: function() {
      var self = this; 
      var r;
      var super$ = this.super$.to_s;
      r = [];
      self.each(function(k, v) {
        return r.push(S(k, "=>", v));
      });
      return S("{ ", r.join(", "), " }");
    },

    clone: function() {
      var self = this; 
      var super$ = this.super$.clone;
      return self;
    }
  });

  var HashEnv = MakeClass( {
    include: [ BaseEnv ],

    initialize: function(hash) {
      var self = this; 
      if (hash === undefined) hash = new EnsoHash ( { } );
      var super$ = this.super$.initialize;
      return self.$.hash = hash;
    },

    _get: function(key) {
      var self = this; 
      var super$ = this.super$._get;
      if (self.$.hash.has_key_P(key)) {
        return self.$.hash._get(key);
      } else {
        return self.$.parent && self.$.parent._get(key);
      }
    },

    _set: function(key, value) {
      var self = this; 
      var super$ = this.super$._set;
      if (self.$.parent && self.$.parent.has_key_P(key)) {
        return self.$.parent ._set( key , value );
      } else {
        return self.$.hash ._set( key , value );
      }
    },

    has_key_P: function(key) {
      var self = this; 
      var super$ = this.super$.has_key_P;
      return self.$.hash.has_key_P(key) || self.$.parent && self.$.parent.has_key_P(key);
    },

    to_s: function() {
      var self = this; 
      var super$ = this.super$.to_s;
      return self.$.hash.to_s();
    },

    clone: function() {
      var self = this; 
      var r;
      var super$ = this.super$.clone;
      r = HashEnv.new(self.$.hash.clone());
      r.set_parent(self.$.parent);
      return r;
    }
  });

  var ObjEnv = MakeClass( {
    include: [ BaseEnv ],

    obj: function() { return this.$.obj },

    initialize: function(obj, parent) {
      var self = this; 
      if (parent === undefined) parent = null;
      var super$ = this.super$.initialize;
      self.$.obj = obj;
      return self.$.parent = parent;
    },

    _get: function(key) {
      var self = this; 
      var super$ = this.super$._get;
      if (key == "self") {
        return self.$.obj;
      } else if (self.$.obj.schema_class().all_fields().any_P(function(f) {
        return f.name() == key;
      })) {
        return self.$.obj._get(key);
      } else {
        return self.$.parent && self.$.parent._get(key);
      }
    },

    _set: function(key, value) {
      var self = this; 
      var super$ = this.super$._set;
      return self.$.obj ._set( key , value );
    },

    has_key_P: function(key) {
      var self = this; 
      var super$ = this.super$.has_key_P;
      return self.$.obj.schema_class().all_fields()._get(key) || self.$.parent && self.$.parent.has_key_P(key);
    },

    to_s: function() {
      var self = this; 
      var super$ = this.super$.to_s;
      return self.$.obj.to_s();
    },

    type: function(fname) {
      var self = this; 
      var super$ = this.super$.type;
      return self.$.obj.schema_class().all_fields()._get(fname).type();
    },

    clone: function() {
      var self = this; 
      var super$ = this.super$.clone;
      return self;
    }
  });

  var LambdaEnv = MakeClass( {
    include: [ BaseEnv ],

    initialize: function(block, label) {
      var self = this; 
      var super$ = this.super$.initialize;
      self.$.label = label;
      return self.$.block = block;
    },

    _get: function(key) {
      var self = this; 
      var res;
      var super$ = this.super$._get;
      if (self.$.label == key) {
        res = self.$.block.call();
        return res;
      } else {
        return self.$.parent && self.$.parent._get(key);
      }
    },

    _set: function(key, value) {
      var self = this; 
      var super$ = this.super$._set;
      if (self.$.label == key) {
        return self.raise(S("Trying to modify read-only variable ", key));
      } else {
        return self.$.parent ._set( key , value );
      }
    },

    has_key_P: function(key) {
      var self = this; 
      var super$ = this.super$.has_key_P;
      return self.$.label == key || self.$.parent && self.$.parent.has_key_P(key);
    },

    to_s: function() {
      var self = this; 
      var super$ = this.super$.to_s;
      return self.$.block.to_s();
    },

    clone: function() {
      var self = this; 
      var super$ = this.super$.clone;
      return self;
    }
  });

  Env = {
    BaseEnv: BaseEnv,
    HashEnv: HashEnv,
    ObjEnv: ObjEnv,
    LambdaEnv: LambdaEnv,

  };
  return Env;
})
