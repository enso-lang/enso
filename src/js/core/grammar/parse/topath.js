define([
  "core/system/utils/paths"
],
function(Paths) {
  var Topath ;
  var ToPath = MakeClass("ToPath", null, [],
    function() {
      this.to_path = function(path, it) {
        var self = this; 
        return self.new(it).eval(path);
      };
    },
    function(super$) {
      this.initialize = function(it) {
        var self = this; 
        return self.$.it = it;
      };

      this.eval = function(this_V) {
        var self = this; 
        puts("MAKING " + this_V.schema_class().name());
        return self.send(this_V.schema_class().name(), this_V);
      };

      this.Anchor = function(this_V) {
        var self = this; 
        return Paths.Path.new();
      };

      this.Sub = function(this_V) {
        var self = this; 
        var p;
        p = this_V.parent()
          ? self.eval(this_V.parent())
          : Paths.Path.new([Paths.Root.new()]);
        puts("SUB " + p);
        if (this_V.key()) {
          return p.field(this_V.name()).key(self.eval(this_V.key()));
        } else {
          return p.field(this_V.name());
        }
      };

      this.It = function(this_V) {
        var self = this; 
        return self.$.it;
      };

      this.Const = function(this_V) {
        var self = this; 
        return this_V.value();
      };
    });

  Topath = {
    ToPath: ToPath,

  };
  return Topath;
})
