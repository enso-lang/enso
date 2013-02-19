define([
],
function() {

  var Env ;
  var BaseEnv = MakeMixin({
    set_in_place: function(block, key) {
      var self = this; 
      return self._set(key, block(self._get(key)));
    },

    set: function(block, key) {
      var self = this; 
      var res;
      res = self.clone();
      res.set_in_place(key, block);
      return res;
    },

    set_parent: function(env) {
      var self = this; 
      self.$.parent = env;
      return self;
    },

    set_grandparent: function(env) {
      var self = this; 
      if (self.$.parent == null || self.$.parent == new EnsoHash ( { } )) {
        return self.set_parent(env);
      } else {
        return self.$.parent.set_grandparent(env);
      }
    },

    add: function(env) {
      var self = this; 
      self.set_parent(env);
      return self;
    },

    to_s: function() {
      var self = this; 
      var r;
      r = [];
      self.each(function(k, v) {
        return r.push(S(k, "=>", v));
      });
      return S("{ ", r.join(", "), " }");
    },

    clone: function() {
      var self = this; 
      return self;
    }
  });

  var HashEnv = MakeClass( function(super$) { return {
    include: [ BaseEnv ],

    initialize: function(hash) {
      var self = this; 
      if (hash === undefined) hash = new EnsoHash ( { } );
      return self.$.hash = hash;
    },

    _get: function(key) {
      var self = this; 
      if (self.$.hash.has_key_P(key)) {
        return self.$.hash._get(key);
      } else {
        return self.$.parent && self.$.parent._get(key);
      }
    },

    _set: function(key, value) {
      var self = this; 
      if (self.$.parent && self.$.parent.has_key_P(key)) {
        return self.$.parent._set(key, value);
      } else {
        return self.$.hash._set(key, value);
      }
    },

    has_key_P: function(key) {
      var self = this; 
      return self.$.hash.has_key_P(key) || self.$.parent && self.$.parent.has_key_P(key);
    },

    to_s: function() {
      var self = this; 
      return self.$.hash.to_s();
    },

    clone: function() {
      var self = this; 
      var r;
      r = HashEnv.new(self.$.hash.clone());
      r.set_parent(self.$.parent);
      return r;
    }
  }});

  var ObjEnv = MakeClass( function(super$) { return {
    include: [ BaseEnv ],

    obj: function() { return this.$.obj },

    initialize: function(obj, parent) {
      var self = this; 
      if (parent === undefined) parent = null;
      self.$.obj = obj;
      return self.$.parent = parent;
    },

    _get: function(key) {
      var self = this; 
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
      return self.$.obj._set(key, value);
    },

    has_key_P: function(key) {
      var self = this; 
      return self.$.obj.schema_class().all_fields()._get(key) || self.$.parent && self.$.parent.has_key_P(key);
    },

    to_s: function() {
      var self = this; 
      return self.$.obj.to_s();
    },

    type: function(fname) {
      var self = this; 
      return self.$.obj.schema_class().all_fields()._get(fname).type();
    },

    clone: function() {
      var self = this; 
      return self;
    }
  }});

  var LambdaEnv = MakeClass( function(super$) { return {
    include: [ BaseEnv ],

    initialize: function(block, label) {
      var self = this; 
      self.$.label = label;
      return self.$.block = block;
    },

    _get: function(key) {
      var self = this; 
      var res;
      if (self.$.label == key) {
        res = self.$.block();
        return res;
      } else {
        return self.$.parent && self.$.parent._get(key);
      }
    },

    _set: function(key, value) {
      var self = this; 
      if (self.$.label == key) {
        return self.raise(S("Trying to modify read-only variable ", key));
      } else {
        return self.$.parent._set(key, value);
      }
    },

    has_key_P: function(key) {
      var self = this; 
      return self.$.label == key || self.$.parent && self.$.parent.has_key_P(key);
    },

    to_s: function() {
      var self = this; 
      return self.$.block.to_s();
    },

    clone: function() {
      var self = this; 
      return self;
    }
  }});

  Env = {
    BaseEnv: BaseEnv,
    HashEnv: HashEnv,
    ObjEnv: ObjEnv,
    LambdaEnv: LambdaEnv,

  };
  return Env;
})
