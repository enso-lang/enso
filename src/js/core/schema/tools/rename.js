self.require("core/system/library/schema");
self.require("core/system/utils/paths");
self.require("core/schema/tools/copy");
(this.paths = (function (block, obj, path) {
  var self = this;
  (path = (((typeof path) !== "undefined") ? path : []));
  var current, field, key;
  (field = obj.schema_class().key());
  (current = path);
  if (field) {
    (key = obj._get(field.name()));
    (current = (path + obj._get(field.name())));
  }
  return obj.schema_class().defined_fields().each((function (f) {
    if (f.computed()) {
      self.next();
    }
    if ((!f.traversal())) {
      self.next();
    }
    if (f.many()) { 
      return obj._get(f.name()).each((function (elt) {
        return self.paths(block, elt, current);
      })); 
    }
    else { 
      if (f.optional()) { 
        if ((!((obj._get(f.name()) == null) || f.type().Primitive_P()))) {
          return self.paths(block, obj._get(f.name()), current);
        } 
      }
      else { 
        if ((!f.type().Primitive_P())) {
          return self.paths(block, obj._get(f.name()), current);
        }
      }
    }
  }));
}));
(this.map_names_C = (function (block, obj) {
  var self = this;
  var x, field, key;
  (field = obj.schema_class().key());
  if (field) {
    (key = obj._get(field.name()));
    (x = (function () {
    })());
    if (x) {
      obj._set(field.name(), x);
    }
  }
  return obj.schema_class().defined_fields().each((function (f) {
    if (f.computed()) {
      self.next();
    }
    if ((!f.traversal())) {
      self.next();
    }
    if (f.many()) { 
      return obj._get(f.name()).each((function (elt) {
        return self.map_names_C(block, elt);
      })); 
    }
    else { 
      if (f.optional()) { 
        if ((!((obj._get(f.name()) == null) || f.type().Primitive_P()))) {
          return self.map_names_C(block, obj._get(f.name()));
        } 
      }
      else { 
        if ((!f.type().Primitive_P())) {
          return self.map_names_C(block, obj._get(f.name()));
        }
      }
    }
  }));
}));
(this.prime_C = (function (obj, prefix) {
  var self = this;
  (prefix = (((typeof prefix) !== "undefined") ? prefix : "_"));
  return self.map_names_C((function (name) {
    return S("", prefix, ".", name, "");
  }), obj);
}));
(this.prime = (function (obj, prefix) {
  var self = this;
  (prefix = (((typeof prefix) !== "undefined") ? prefix : "_"));
  (obj = self.Clone(obj));
  self.prime_C(obj, prefix);
  return self.return(obj);
}));
(this.rename_C = (function (obj, map) {
  var self = this;
  var map2, field, key;
  (field = obj.schema_class().key());
  (map2 = (new EnsoHash({
    
  })));
  if (field) { 
    map.each((function (k, v) {
      var name;
      (name = obj._get(field.name()));
      if ((System.test_type(k, self.Hash()) && k._get(name))) { 
        return map2._set(k._get(name), v); 
      }
      else { 
        return map2._set(k, v);
      }
    })); 
  }
  else { 
    (map2 = map);
  }
  if (field) {
    (key = obj._get(field.name()));
    if (map._get(key)) {
      obj._set(field.name(), map._get(key));
    }
  }
  return self.rename_fields_C(obj, map2);
}));
(this.rename_fields_C = (function (obj, map) {
  var self = this;
  obj.schema_class().defined_fields().each((function (f) {
    if (f.computed()) {
      self.next();
    }
    if ((!f.traversal())) {
      self.next();
    }
    if (f.many()) {
      obj._get(f.name()).each((function (elt) {
        return self.rename_C(elt, map);
      }));
      if (f.type().key()) {
        return obj._get(f.name())._recompute_hash_C();
      }
    }
    else {
      if ((!((obj._get(f.name()) == null) || f.type().Primitive_P()))) {
        return self.rename_C(obj._get(f.name()), map);
      }
    }
  }));
  return obj;
}));
(this.rename = (function (obj, map) {
  var self = this;
  (obj = self.Clone(obj));
  self.rename_C(obj, map);
  return self.return(obj);
}));