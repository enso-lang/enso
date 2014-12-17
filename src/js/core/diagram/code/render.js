define([
  "core/expr/code/renderexp",
  "core/semantics/code/interpreter"
],
function(Renderexp, Interpreter) {
  var Render ;

  var RenderStencil = MakeMixin([Interpreter.Dispatcher, Renderexp.RenderExpr], function() {
    this.render = function(obj) {
      var self = this; 
      return self.dispatch_obj("render", obj);
    };

    this.render_Stencil = function(obj) {
      var self = this; 
      return self.this().render(obj.body());
    };

    this.render_Container = function(obj) {
      var self = this; 
      var dom, t, row, grid, col;
      self.var(dom);
      if (obj.direction() == 1) {
        dom = "<div>";
        Range.new(0, obj.items().size() - 1).each(function(i) {
          self.var(t = self.this().render(obj.items()._get(i)));
          return dom.append(t);
        });
      } else if (obj.direction() == 2) {
        dom = "<table>";
        self.var(row = "<tr>");
        self.var(grid = false);
        if (self.this().in_grid() > 0) {
          grid = true;
        }
        Range.new(0, obj.items().size() - 1).each(function(i) {
          self.var(t = self.this().render(obj.items()._get(i)));
          self.var(col = "<td>");
          col.append(t);
          return row.append(col);
        });
        dom.append(row);
        if (grid) {
          dom = row;
        }
      } else if (obj.direction() == 3) {
        dom = "<table>";
        Range.new(0, obj.items().size() - 1).each(function(i) {
          self.var(row = self.this().render(obj.items()._get(i)));
          return dom.append(row);
        });
      } else if (obj.direction() == 4) {
        dom = "<div>";
        Range.new(0, obj.items().size() - 1).each(function(i) {
          self.var(t = self.this().render(obj.items()._get(i)));
          return dom.append(t);
        });
      } else if (obj.direction() == 5) {
        dom = "<div>";
        Range.new(0, obj.items().size() - 1).each(function(i) {
          self.var(t = self.this().render(obj.items()._get(i)));
          return dom.append(t);
        });
      }
      self.this().make_style(dom, obj.props());
      return dom;
    };

    this.update_Pages = function(doms, list, nval) {
      var self = this; 
      self.console().log(S("dom=", doms.current(), "  val=", nval));
      if (doms.current() != nval) {
        self.console().log(S("Flipping page from ", doms.current(), " to ", nval));
        list._get(doms.current()).hide();
        self.console().log(S("hiding ", list._get(doms.current())));
        list._get(nval).show();
        self.console().log(S("showing ", list._get(nval)));
        return doms.set_current(nval);
      }
    };

    this.render_Pages = function(obj) {
      var self = this; 
      var index, doms, list, item_dom, path, env, srcs, addr, nval;
      self.var(index = obj.current().val());
      self.var(doms = "<div>");
      self.var(list = []);
      Range.new(0, obj.items().size() - 1).each(function(i) {
        self.var(item_dom = self.this().render(obj.items()._get(i)));
        doms.append(item_dom);
        list._set(i, item_dom);
        return item_dom.hide();
      });
      self.var(path = self.mm()._get(obj.current().to_s()));
      self.var(env = new EnsoHash ({ }));
      env._set("root", self.data());
      doms._set("current", Eval.eval(path, new EnsoHash ({ env: env })));
      list._get(doms.current()).show();
      if (path != self.null()) {
        srcs = Invert.getSources(path);
        Range.new(0, srcs.items().size() - 1).each(function(i) {
          self.var(addr = Lvalue.lvalue(srcs._get(i), new EnsoHash ({ env: env })));
          self.console().log(S("adding listener to addr: ", addr.object(), ".", addr.index()));
          return addr.object().add_listener(function(val) {
            self.var(nval = Eval.eval(path, new EnsoHash ({ env: env })));
            self.console().log(S("changed value in ", addr.object(), ".", addr.index(), " to ", nval));
            self.console().log(S("dom=", doms.current(), "  val=", nval));
            if (doms.current() != nval) {
              self.console().log(S("Flipping page from ", doms.current(), " to ", nval));
              list._get(doms.current()).hide();
              self.console().log(S("hiding ", list._get(doms.current())));
              list._get(nval).show();
              self.console().log(S("showing ", list._get(nval)));
              return doms.set_current(nval);
            }
          }, addr.index().to_s());
        });
      }
      return doms;
    };

    this.render_Space = function(obj) {
      var self = this; 
      return "<div>";
    };

    this.render_Text = function(obj) {
      var self = this; 
      var dom, path, env, srcs, addr, nval;
      self.var(dom = "<div>");
      self.this().make_style(dom, obj.props());
      dom.text(obj.string().val().to_s());
      self.var(path = self.mm()._get(obj.string().to_s()));
      if (path != self.null()) {
        self.var(env = new EnsoHash ({ }));
        env._set("root", self.data());
        srcs = Invert.getSources(path);
        dom.dblclick(function() {
          return self.drawtree(path);
        });
        Range.new(0, srcs.items().size() - 1).each(function(i) {
          self.var(addr = Lvalue.lvalue(srcs._get(i), new EnsoHash ({ env: env })));
          self.console().log(S("adding listener to addr: ", addr.object(), ".", addr.index()));
          return addr.object().add_listener(function() {
            self.var(nval = Eval.eval(path, new EnsoHash ({ env: env })));
            self.console().log(S("changed value in ", addr.object(), ".", addr.index(), " to ", nval));
            return dom.text(nval.to_s());
          }, addr.index().to_s());
        });
      }
      dom.append("<p>");
      return dom;
    };

    this.render_TextBox = function(obj) {
      var self = this; 
      var dom, type, path, env, ui_value, model_value, addr;
      self.var(dom = "<input type='text'>");
      self.this().make_style(dom, obj.props());
      dom.text(obj.value().val().to_s());
      self.var(type = obj.type().val().to_s());
      self.var(path = self.mm()._get(obj.value().to_s()));
      if (path != self.null()) {
        self.var(env = new EnsoHash ({ }));
        env._set("root", self.data());
        dom.keyup(function() {
          self.var(ui_value = self.coercefromstr(type, self.this().val()));
          self.var(model_value = Eval.eval(path, new EnsoHash ({ env: env })));
          if (ui_value.to_s() != model_value) {
            self.console().log(S("setting ", path, " to ", ui_value));
            addr = Lvalue.lvalue(path, new EnsoHash ({ env: env }));
            self.console().log(S("addr: ", addr.object(), "..", addr.index()));
            return addr.set(ui_value);
          }
        }).keyup();
      }
      return dom;
    };

    this.render_SelectMulti = function(obj) {
      var self = this; 
      var dom, arrange, too_long, choice, line;
      self.var(dom = "<form>");
      self.this().make_style(dom, obj.props());
      self.var(arrange = obj.props()._get("arrange"));
      if (arrange != "vertical" && arrange != "horizontal") {
        self.var(too_long = false);
        obj.choices().each(function() {
          if (self.c().val().size() > 20) {
            return too_long = true;
          }
        });
        if (too_long) {
          arrange = "vertical";
        }
      }
      Range.new(0, obj.choices().items().size() - 1).each(function(i) {
        self.var(choice = obj.choices()._get(i));
        self.var(line = S("<input type='checkbox' name='", obj._id().toString(), "'>", choice.val(), "</input>"));
        if (arrange == "vertical") {
          line = line + "<br>";
        }
        return dom.append(line);
      });
      return dom;
    };

    this.render_SelectSingle = function(obj) {
      var self = this; 
      var dom, arrange, too_long, type, choice, name, line, sel;
      self.var(dom = "<form>");
      self.this().make_style(dom, obj.props());
      self.var(arrange = obj.props()._get("arrange"));
      if (arrange != "vertical" && arrange != "horizontal") {
        self.var(too_long = false);
        obj.choices().each(function() {
          if (self.c().val().size() > 20) {
            return too_long = true;
          }
        });
        if (too_long) {
          arrange = "vertical";
        }
      }
      self.var(type = obj.props()._get("type"));
      if (type != "radio" && type != "dropdown") {
        if (obj.choices().size() < 5) {
          type = "radio";
        } else {
          type = "dropdown";
        }
      }
      if (type == "radio") {
        Range.new(0, obj.choices().items().size() - 1).each(function(i) {
          self.var(choice = obj.choices()._get(i));
          self.var(name = S("x", obj._id().toString()));
          self.var(line = S("<input type='radio' name='", name, "' value='", choice.val(), "'>", choice.val(), "</input>"));
          if (arrange == "vertical") {
            line = line + "<br>";
          }
          return dom.append(line);
        });
      } else {
        self.var(sel = S("<select name='", obj._id().toString(), "'>"));
        Range.new(0, obj.choices().size() - self.i()).each(function(i) {
          self.var(choice = obj.choices()._get(i));
          self.var(line = S("<option value='", choice.val(), "'>", choice.val(), "</option>"));
          self.console().log(line);
          return sel.append(line);
        });
        self.console().log("<select name='", obj._id().toString(), "'></select>");
        dom.append(sel);
      }
      return dom;
    };
  });

  var RenderStencilC = MakeClass("RenderStencilC", null, [RenderStencil],
    function() {
    },
    function(super$) {
    });

  Render = {
    render: function(obj, args) {
      var self = this; 
      if (args === undefined) args = new EnsoHash ({ });
      var interp;
      interp = RenderStencilC.new();
      return interp.dynamic_bind(function() {
        return interp.render(obj);
      }, args);
    },

    RenderStencil: RenderStencil,
    RenderStencilC: RenderStencilC,

  };
  return Render;
})
