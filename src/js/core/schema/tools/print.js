define([
],
function() {
  var Print ;
  var Print = MakeClass("Print", null, [],
    function() {
      this.print = function(obj, depth) {
        var self = this; 
        if (depth === undefined) depth = null;
        return self.new(System.stdout(), depth).print(obj);
      };

      this.to_s = function(obj, depth) {
        var self = this; 
        if (depth === undefined) depth = null;
        var output;
        output = "";
        self.new(output, depth).print(obj);
        return output;
      };
    },
    function(super$) {
      this.initialize = function(output, depth) {
        var self = this; 
        if (output === undefined) output = System.stdout();
        if (depth === undefined) depth = null;
        self.$.output = output;
        return self.$.depth = depth;
      };

      this.print = function(obj, indent, back_link) {
        var self = this; 
        if (indent === undefined) indent = 0;
        if (back_link === undefined) back_link = null;
        var klass, data, sub, subindent;
        if (! obj.respond_to_P("schema_class")) {
          return self.$.output.push(S(obj, "\n"));
        } else if (obj == null) {
          return self.$.output.push("nil\n");
        } else {
          klass = obj.schema_class();
          self.$.output.push(S(klass.name(), " ", obj._id(), "\n"));
          indent = indent + 2;
          return klass.fields().each(function(field) {
            if (field != back_link) {
              if (field.type().Primitive_P()) {
                data = field.type().name() == "str"
                  ? S("\"", obj._get(field.name()), "\"")
                  : obj._get(field.name());
                return self.$.output.push(S(" ".repeat(indent), field.name(), ": ", data, "\n"));
              } else if (! field.many()) {
                sub = obj._get(field.name());
                self.$.output.push(S(" ".repeat(indent), field.name(), ": "));
                if (self.$.depth && indent > self.$.depth * 2) {
                  return self.$.output.push("...\n");
                } else {
                  return self.print1(field.traversal(), sub, indent, field.inverse());
                }
              } else if (! obj._get(field.name()).empty_P()) {
                self.$.output.push(S(" ".repeat(indent), field.name()));
                subindent = indent + 2;
                if (self.$.depth && indent > self.$.depth * 2) {
                  return self.$.output.push(" ...\n");
                } else {
                  self.$.output.push("\n");
                  return obj._get(field.name()).each_with_index(function(sub, i) {
                    self.$.output.push(S(" ".repeat(subindent), "#", i, " "));
                    return self.print1(field.traversal(), sub, subindent, field.inverse());
                  });
                }
              }
            }
          });
        }
      };

      this.print1 = function(traversal, obj, indent, back_link) {
        var self = this; 
        if (obj == null) {
          return self.$.output.push("nil\n");
        } else if (traversal) {
          return self.print(obj, indent, back_link);
        } else {
          return self.$.output.push(S(obj._path(), "\n"));
        }
      };
    });

  Print = {
    Print: Print,

  };
  return Print;
})
