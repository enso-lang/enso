define([
  "core/expr/code/render",
  "core/diagram/code/construct",
  "core/semantics/code/interpreter"
],
function(Render, Construct, Interpreter) {
  var Render ;

  var RenderStencil = MakeMixin([Interpreter.Dispatcher, Render.RenderExpr, Construct.EvalExpr], function() {
    this.render_Stencil = function(obj) {
      var self = this; 
      var pre, post, body;
      pre = ("\n<!DOCTYPE html>\n<html>\n<head>\n<script src=\"./lib/jquery-1.9.1.min.js\">\n</script>\n<title>" + obj.title().to_s()) + "</title>\n</head>\n<body>\n      ";
      post = "\n</body>\n</html>\n      ";
      body = self.dynamic_bind(function() {
        return self.render(obj.body());
      }, new EnsoHash ({ env: new EnsoHash ({ }) }));
      return (pre + body) + post;
    };

    this.render_Container = function(obj) {
      var self = this; 
      var res;
      res = "<table>\\n";
      if (obj.direction() == 2) {
        res = res + "<tr>";
      }
      res = res + obj.items().inject(function(memo, item) {
        if (obj.direction() == 1) {
          return ((memo + "<tr><td>") + self.render(item)) + "</td></tr>\\n";
        } else if (obj.direction() == 2) {
          return ((memo + "<td>") + self.render(item)) + "</td>";
        }
      }, "");
      if (obj.direction() == 2) {
        res = res + "</tr>";
      }
      res = res + "</table>\\n";
      return res;
    };

    this.render_Shape = function(obj) {
      var self = this; 
      return self.render(obj.content());
    };

    this.render_Text = function(obj) {
      var self = this; 
      return self.render(obj.string());
    };

    this.render_TextBox = function(obj) {
      var self = this; 
      return S("<input type=\"text\" name=\"\" value=\"", self.render(obj.value()), "\">");
    };

    this.render_Pages = function(obj) {
      var self = this; 
      var index;
      index = Construct.eval(obj.current(), new EnsoHash ({ env: self.$.D._get("env") }));
      if (index >= obj.items().size()) {
        self.raise("Trying to render an out of bounds page");
      }
      return self.render(obj.items()._get(index));
    };

    this.render__P = function(obj) {
      var self = this; 
      return "";
    };
  });

  var RenderStencilC = MakeClass("RenderStencilC", null, [RenderStencil],
    function() {
    },
    function(super$) {
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
