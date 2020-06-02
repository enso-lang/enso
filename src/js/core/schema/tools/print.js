'use strict'

//// Print ////

var cwd = process.cwd() + '/';

var Print;

var print = function(obj) {
  var self = this;
  return PrintC.print(obj);
};

class PrintC {
  static new(...args) { return new PrintC(...args) };

  static print(obj, depth = null) {
    var self = this;
    return self.new(Enso.System.stdout(), depth).print(obj);
  };

  static to_s(obj, depth = null) {
    var self = this, output;
    output = "";
    self.new(output, depth).print(obj);
    return output;
  };

  constructor(output = Enso.System.stdout(), depth = null) {
    var self = this;
    self.output$ = output;
    self.depth$ = depth;
  };

  print(obj, indent = 0, back_link = null) {
    var self = this, klass, data, sub, subindent;
    if (! obj.respond_to_P("schema_class")) {
      return self.output$.push(Enso.S(obj, "\n"));
    } else if (obj == null) {
      return self.output$.push("nil\n");
    } else {
      klass = obj.schema_class();
      self.output$.push(Enso.S(klass.name(), " ", obj.identity(), "\n"));
      indent = indent + 2;
      return klass.fields().each(function(field) {
        if (field != back_link) {
          if (Enso.System.test_type(field.type(), "Primitive")) {
            data = field.type().name() == "str"
              ? Enso.S("\"", obj.get$(field.name()), "\"")
              : obj.get$(field.name());
            return self.output$.push(Enso.S(" ".repeat(indent), field.name(), ": ", data, "\n"));
          } else if (! field.many()) {
            sub = obj.get$(field.name());
            self.output$.push(Enso.S(" ".repeat(indent), field.name(), ": "));
            if (self.depth$ && indent > self.depth$ * 2) {
              return self.output$.push("...\n");
            } else {
              return self.print1(field.traversal(), sub, indent, field.inverse());
            }
          } else if (! obj.get$(field.name()).empty_P()) {
            self.output$.push(Enso.S(" ".repeat(indent), field.name()));
            subindent = indent + 2;
            if (self.depth$ && indent > self.depth$ * 2) {
              return self.output$.push(" ...\n");
            } else {
              self.output$.push("\n");
              return obj.get$(field.name()).each_with_index(function(sub, i) {
                self.output$.push(Enso.S(" ".repeat(subindent), "#", i, " "));
                return self.print1(field.traversal(), sub, subindent, field.inverse());
              });
            }
          }
        }
      });
    }
  };

  print1(traversal, obj, indent, back_link) {
    var self = this;
    if (obj == null) {
      return self.output$.push("nil\n");
    } else if (traversal) {
      return self.print(obj, indent, back_link);
    } else {
      return self.output$.push(Enso.S(obj._path(), "\n"));
    }
  };
};

Print = {
  print: print,
  PrintC: PrintC,
};
module.exports = Print ;
