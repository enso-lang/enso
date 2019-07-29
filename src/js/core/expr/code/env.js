define([], (function () {
  var Env;
  var BaseEnv = MakeMixin([], (function () {
    (this.set_C = (function (block, key) {
      var self = this;
      return self._set(key, block(self._get(key)));
    }));
    (this.set = (function (block, key) {
      var self = this;
      var res;
      (res = self.clone());
      res.set_C(key, block);
      return res;
    }));
    (this.set_parent = (function (env) {
      var self = this;
      (self.$.parent = env);
      return self;
    }));
    (this.set_grandparent = (function (env) {
      var self = this;
      if (((self.$.parent == null) || (self.$.parent == (new EnsoHash({
        
      }))))) { 
        return self.set_parent(env); 
      }
      else { 
        return self.$.parent.set_grandparent(env);
      }
    }));
    (this.to_s = (function () {
      var self = this;
      var r;
      (r = []);
      self.each((function (k, v) {
        return r.push(S("", k, "=>", v, ""));
      }));
      return S("{ ", r.join(", "), " }");
    }));
  }));
  var HashEnv = MakeClass("HashEnv", null, [BaseEnv], (function () {
  }), (function (super$) {
    (this.initialize = (function (hash, parent) {
      var self = this;
      (hash = (((typeof hash) !== "undefined") ? hash : (new EnsoHash({
        
      }))));
      (parent = (((typeof parent) !== "undefined") ? parent : null));
      (self.$.hash = hash);
      return (self.$.parent = parent);
    }));
    (this._get = (function (key) {
      var self = this;
      (key = key.to_s());
      if (self.$.hash.has_key_P(key)) { 
        return self.$.hash._get(key); 
      }
      else { 
        return (self.$.parent && self.$.parent._get(key));
      }
    }));
    (this._set = (function (key, value) {
      var self = this;
      (key = key.to_s());
      if (self.$.hash.has_key_P(key)) { 
        return self.$.hash._set(key, value); 
      }
      else { 
        if ((self.$.parent && self.$.parent.has_key_P(key))) { 
          return self.$.parent._set(key, value); 
        }
        else { 
          return self.$.hash._set(key, value);
        }
      }
    }));
    (this.has_key_P = (function (key) {
      var self = this;
      (key = key.to_s());
      return (self.$.hash.has_key_P(key) || (self.$.parent && self.$.parent.has_key_P(key)));
    }));
    (this.keys = (function () {
      var self = this;
      return (self.$.hash.keys() + ((self.$.parent == null) ? [] : self.$.parent.keys())).uniq();
    }));
    (this.to_s = (function () {
      var self = this;
      return S("", self.$.hash.to_s(), "-", self.$.parent, "");
    }));
    (this.clone = (function () {
      var self = this;
      return self;
    }));
  }));
  var ObjEnv = MakeClass("ObjEnv", null, [BaseEnv], (function () {
  }), (function (super$) {
    (this.obj = (function () {
      return this.$.obj;
    }));
    (this.initialize = (function (obj, parent) {
      var self = this;
      (parent = (((typeof parent) !== "undefined") ? parent : null));
      (self.$.obj = obj);
      return (self.$.parent = parent);
    }));
    (this._get = (function (key) {
      var self = this;
      if ((key == "self")) { 
        return self.$.obj; 
      }
      else { 
        if (self.$.obj.schema_class().all_fields().any_P((function (f) {
          return (f.name() == key);
        }))) { 
          return self.$.obj._get(key); 
        }
        else { 
          return (self.$.parent && self.$.parent._get(key));
        }
      }
    }));
    (this._set = (function (key, value) {
      var self = this;
      try {return self.$.obj._set(key, value);
           
      }
      catch (caught$2091) {
        
          return (self.$.parent && self.$.parent._set(key, value));
      }
    }));
    (this.has_key_P = (function (key) {
      var self = this;
      return (((key == "self") || self.$.obj.schema_class().all_fields()._get(key)) || (self.$.parent && self.$.parent.has_key_P(key)));
    }));
    (this.keys = (function () {
      var self = this;
      return (self.$.obj.schema_class().all_fields().keys() + ((self.$.parent == null) ? [] : self.$.parent.keys())).uniq();
    }));
    (this.to_s = (function () {
      var self = this;
      return S("", self.$.obj.to_s(), "-", self.$.parent, "");
    }));
    (this.type = (function (fname) {
      var self = this;
      var x;
      (x = self.$.obj.schema_class().all_fields()._get(fname));
      if ((x == null)) { 
        return self.raise(S("Unkown field ", fname, " @{@obj.schema_class}")); 
      }
      else { 
        return x.type();
      }
    }));
  }));
  var LambdaEnv = MakeClass("LambdaEnv", null, [BaseEnv], (function () {
  }), (function (super$) {
    (this.initialize = (function (block, label, parent) {
      var self = this;
      (parent = (((typeof parent) !== "undefined") ? parent : null));
      (self.$.label = label);
      (self.$.block = block);
      return (self.$.parent = parent);
    }));
    (this._get = (function (key) {
      var self = this;
      if ((self.$.label == key)) { 
        return self.$.block(); 
      }
      else { 
        return (self.$.parent && self.$.parent._get(key));
      }
    }));
    (this._set = (function (key, value) {
      var self = this;
      if ((self.$.label == key)) { 
        return self.raise(S("Trying to modify read-only variable ", key, "")); 
      }
      else { 
        return self.$.parent._set(key, value);
      }
    }));
    (this.has_key_P = (function (key) {
      var self = this;
      return ((self.$.label == key) || (self.$.parent && self.$.parent.has_key_P(key)));
    }));
    (this.keys = (function () {
      var self = this;
      return ([self.$.label] + ((self.$.parent == null) ? [] : self.$.parent.keys())).uniq();
    }));
    (this.to_s = (function () {
      var self = this;
      return S("", self.$.block.to_s(), "-", self.$.parent, "");
    }));
  }));
  (Env = {
    LambdaEnv: LambdaEnv,
    ObjEnv: ObjEnv,
    BaseEnv: BaseEnv,
    HashEnv: HashEnv
  });
  return Env;
}));