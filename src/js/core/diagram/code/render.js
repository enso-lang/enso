define([
  "core/expr/code/render",
  "core/diagram/code/construct",
  "core/semantics/code/interpreter"
],
function(Render, Construct, Interpreter) {
  var Render ;

  var RenderStencil = MakeMixin([Interpreter.Dispatcher, Render.RenderExpr, Construct.EvalExpr], function() {
    this.render_Stencil = function(title, root, body) {
      var self = this; 
      var pre, post, body;
      pre = ("\n<!DOCTYPE html>\n<html>\n<head>\n<script src=\"./lib/jquery-1.9.1.min.js\">\n</script>\n<title>" + title.to_s()) + "</title>\n</head>\n<body>\n      ";
      post = "\n</body>\n</html>\n      ";
      body = self.dynamic_bind(function() {
        return self.render(body);
      }, new EnsoHash ({ env: new EnsoHash ({ }) }));
      return (pre + body) + post;
    };

    this.render_Container = function(label, props, direction, items) {
      var self = this; 
      var res;
      res = "<table>\\n";
      if (direction == 2) {
        res = res + "<tr>";
      }
      res = res + items.inject(function(memo, item) {
        if (direction == 1) {
          return ((memo + "<tr><td>") + self.render(item)) + "</td></tr>\\n";
        } else if (direction == 2) {
          return ((memo + "<td>") + self.render(item)) + "</td>";
        }
      }, "");
      if (direction == 2) {
        res = res + "</tr>";
      }
      res = res + "</table>\\n";
      return res;
    };

    this.render_Shape = function(label, props, kind, content) {
      var self = this; 
      return self.render(content);
    };

    this.render_Text = function(label, props, string, editable) {
      var self = this; 
      return self.render(string);
    };

    this.render_TextBox = function(label, props, value) {
      var self = this; 
      return S("<input type=\"text\" name=\"\" value=\"", self.render(value), "\">");
    };

    this.render_Pages = function(label, props, items, current) {
      var self = this; 
      var index;
      index = Construct.eval(current, new EnsoHash ({ env: self.$.D._get("env") }));
      if (index >= items.size()) {
        self.raise("Trying to render an out of bounds page");
      }
      return self.render(items._get(index));
    };

    this.render__P = function(fields, type, args) {
      var self = this; 
      return "";
    };
  });

  var RenderStencilC = MakeClass("RenderStencilC", null, [RenderStencil],
    function() {
    },
    function(super$) {
      this.initialize = function() {
        var self = this; 
      };
    });

  Render = {
    render: function(obj) {
      var self = this; 
      var args = compute_rest_arguments(arguments, 1);
      var interp;
      interp = RenderStencilC.new();
      if (args.empty_P()) {
        return interp.render(obj);
      } else {
        return interp.dynamic_bind(function() {
          return interp.render(obj);
        });
      }
    },

    RenderStencil: RenderStencil,
    RenderStencilC: RenderStencilC,

  };
  return Render;
})
