'use strict'

//// Env ////

var cwd = process.cwd() + '/';
var Enso = require(cwd + "enso.js");

var Env;

function BaseEnv(parent) {
  return class extends parent {
    set_in_place(block, key) {
      var self = this;
      return self .set$(key, block(self.get$(key)));
    };

    set(block, key) {
      var self = this, res;
      res = self.clone();
      res.set_in_place(key, block);
      return res;
    };

    set_parent(env) {
      var self = this;
      self.parent$ = env;
      return self;
    };

    set_grandparent(env) {
      var self = this;
      if (self.parent$ == null || self.parent$ == Enso.EMap.new()) {
        return self.set_parent(env);
      } else {
        return self.parent$.set_grandparent(env);
      }
    };

    to_s() {
      var self = this, r;
      r = [];
      self.each(function(k, v) {
        return r.push(Enso.S(k, "=>", v));
      });
      return Enso.S("{ ", r.join(", "), " }");
    }; }};

class HashEnv extends Enso.mix(Enso.EnsoBaseClass, BaseEnv) {
  static new(...args) { return new HashEnv(...args) };

  constructor(hash = Enso.EMap.new(), parent = null) {
    super();
    var self = this;
    self.hash$ = hash;
    self.parent$ = parent;
  };

  get$(key) {
    var self = this, key;
    key = key.to_s();
    if (self.hash$.has_key_P(key)) {
      return self.hash$.get$(key);
    } else {
      return self.parent$ && self.parent$.get$(key);
    }
  };

  set$(key, value) {
    var self = this, key;
    key = key.to_s();
    if (self.hash$.has_key_P(key)) {
      return self.hash$ .set$(key, value);
    } else if (self.parent$ && self.parent$.has_key_P(key)) {
      return self.parent$ .set$(key, value);
    } else {
      return self.hash$ .set$(key, value);
    }
  };

  has_key_P(key) {
    var self = this, key;
    key = key.to_s();
    return self.hash$.has_key_P(key) || self.parent$ && self.parent$.has_key_P(key);
  };

  keys() {
    var self = this;
    return (self.hash$.keys() + (self.parent$ == null
      ? []
      : self.parent$.keys())).uniq();
  };

  to_s() {
    var self = this;
    return Enso.S(self.hash$.to_s(), "-", self.parent$);
  };
};

class ObjEnv extends Enso.mix(Enso.EnsoBaseClass, BaseEnv) {
  static new(...args) { return new ObjEnv(...args) };

  obj() { return this.obj$ };

  constructor(obj, parent = null) {
    super();
    var self = this;
    self.obj$ = obj;
    self.parent$ = parent;
  };

  get$(key) {
    var self = this;
    if (key == "self") {
      return self.obj$;
    } else if (self.obj$.schema_class().all_fields().any_P(function(f) {
      return f.name() == key;
    })) {
      return self.obj$.get$(key);
    } else {
      return self.parent$ && self.parent$.get$(key);
    }
  };

  set$(key, value) {
    var self = this;
    try {
      return self.obj$ .set$(key, value);
    } catch (DUMMY) {
      return self.parent$ && (self.parent$ .set$(key, value));
    }
  };

  has_key_P(key) {
    var self = this;
    return (key == "self" || self.obj$.schema_class().all_fields().get$(key)) || self.parent$ && self.parent$.has_key_P(key);
  };

  keys() {
    var self = this;
    return (self.obj$.schema_class().all_fields().keys() + (self.parent$ == null
      ? []
      : self.parent$.keys())).uniq();
  };

  to_s() {
    var self = this;
    return Enso.S(self.obj$.to_s(), "-", self.parent$);
  };

  type(fname) {
    var self = this, x;
    x = self.obj$.schema_class().all_fields().get$(fname);
    if (x == null) {
      return self.raise(Enso.S("Unkown field ", fname, " @{@obj.schema_class}"));
    } else {
      return x.type();
    }
  };
};

class LambdaEnv extends Enso.mix(Enso.EnsoBaseClass, BaseEnv) {
  static new(...args) { return new LambdaEnv(...args) };

  constructor(block, label, parent = null) {
    super();
    var self = this;
    self.label$ = label;
    self.block$ = block;
    self.parent$ = parent;
  };

  get$(key) {
    var self = this;
    if (self.label$ == key) {
      return self.block$();
    } else {
      return self.parent$ && self.parent$.get$(key);
    }
  };

  set$(key, value) {
    var self = this;
    if (self.label$ == key) {
      return self.raise(Enso.S("Trying to modify read-only variable ", key));
    } else {
      return self.parent$ .set$(key, value);
    }
  };

  has_key_P(key) {
    var self = this;
    return self.label$ == key || self.parent$ && self.parent$.has_key_P(key);
  };

  keys() {
    var self = this;
    return ([self.label$] + (self.parent$ == null
      ? []
      : self.parent$.keys())).uniq();
  };

  to_s() {
    var self = this;
    return Enso.S(self.block$.to_s(), "-", self.parent$);
  };
};

Env = {
  BaseEnv: BaseEnv,
  HashEnv: HashEnv,
  ObjEnv: ObjEnv,
  LambdaEnv: LambdaEnv,
};
module.exports = Env ;
