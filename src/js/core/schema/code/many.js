SetUtils = MakeModule({
  to_ary: function() {
    var self = this; 
    var super$ = this.super$.to_ary;
    return self.$.values.values();
  },

  add: function(other) {
    var self = this; 
    var r;
    var super$ = this.super$.add;
    r = self.inject(function(x) {
      return x.push();
    }, Set.new(null, self.$.field, self.__key() || other.__key()));
    return other.inject(function(x) {
      return x.push();
    }, r);
  },

  select: function(block) {
    var self = this; 
    var result;
    var super$ = this.super$.select;
    result = Set.new(null, self.$.field, self.__key());
    self.each(function(elt) {
      if (block.call(elt)) {
        return result.push(elt);
      }
    });
    return result;
  },

  flat_map: function(block) {
    var self = this; 
    var new_V, set, key;
    var super$ = this.super$.flat_map;
    new_V = null;
    self.each(function(x) {
      set = block.call(x);
      if (new_V.nil_P()) {
        key = set.__key();
        new_V = Set.new(null, self.$.field, key);
      } else {
      }
      return set.each(function(y) {
        return new_V.push(y);
      });
    });
    return new_V || Set.new(null, self.$.field, self.__key());
  },

  each_with_match: function(block, other) {
    var self = this; 
    var empty;
    var super$ = this.super$.each_with_match;
    empty = Set.new(null, self.$.field, self.__key());
    return self.__outer_join(function(sa, sb) {
      if ((sa && sb) && sa._get(self.__key().name()) == sb._get(self.__key().name())) {
        return block.call(sa, sb);
      } else if (sa) {
        return block.call(sa, null);
      } else if (sb) {
        return block.call(null, sb);
      }
    }, other || empty);
  },

  __key: function() {
    var self = this; 
    var super$ = this.super$.__key;
    return self.$.key;
  },

  __keys: function() {
    var self = this; 
    var super$ = this.super$.__keys;
    return self.$.value.keys();
  },

  __outer_join: function(block, other) {
    var self = this; 
    var keys;
    var super$ = this.super$.__outer_join;
    keys = self.__keys().union(other.__keys());
    return keys.each(function(key) {
      return block.call(self._get(key), other._get(key), key);
    });
  }
});

ListUtils = MakeModule({
  each_with_match: function(block, other) {
    var self = this; 
    var super$ = this.super$.each_with_match;
    if (! self.empty_P()) {
      return self.each(function(item) {
        return block.call(item, null);
      });
    }
  }
});

exports = ManagedData = {
  SetUtils: SetUtils,
  ListUtils: ListUtils,

}
