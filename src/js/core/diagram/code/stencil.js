define(["core/diagram/code/diagram", "core/schema/tools/print", "core/system/load/load", "core/grammar/render/layout", "core/system/library/schema", "core/expr/code/eval", "core/expr/code/lvalue", "core/semantics/code/interpreter", "core/expr/code/renderexp"], (function (Diagram, Print, Load, Layout, Schema, Eval, Lvalue, Interpreter, Renderexp) {
  var Stencil;
  var StencilFrame = MakeClass("StencilFrame", Diagram.DiagramFrame, [], (function () {
  }), (function (super$) {
    (this.selection = (function () {
      return this.$.selection;
    }));
    (this.initialize = (function (win, canvas, context, path) {
      var self = this;
      (path = (((typeof path) !== "undefined") ? path : null));
      super$.initialize.call(self, win, canvas, context, "Model Editor");
      (self.$.actions = (new EnsoHash({
        
      })));
      if (path) {
        return self.set_path(path);
      }
    }));
    (this.set_stencil = (function (val) {
      (this.$.stencil = val);
    }));
    (this.set_path = (function (path) {
      var self = this;
      var ext;
      puts(S("Opening ", path, ""));
      (ext = path.substr((path.lastIndexOf(".") + 1)));
      if ((ext.size() < 2)) {
        self.raise("File has no extension");
      }
      (self.$.path = path);
      return self.setup(ext, Load.load(self.$.path));
    }));
    (this.setup = (function (extension, data) {
      var self = this;
      var size, position_map, pos;
      (self.$.extension = extension);
      (self.$.stencil = Load.load(S("", self.$.extension, ".stencil")));
      if ((!(self.$.stencil.title() == null))) {
        self.set_title(self.$.stencil.title());
      }
      (self.$.data = data);
      self.build_diagram();
      if (data.factory().file_path()._get(0)) {
        (pos = S("", data.factory().file_path()._get(0), "-positions"));
        if (File.exists_P(pos)) {
          (position_map = System.readJSON(pos));
          self.set_positions(position_map);
          if ((!(position_map._get("*WINDOW*") == null))) {
            (size = position_map._get("*WINDOW*"));
          }
        }
      }
      return self.clear_refresh();
    }));
    (this.set_positions = (function (position_map) {
      var self = this;
      return self.$.graphShapes.each((function (tag, shape) {
        var pos, pnt, at1, at2;
        (pnt = position_map._get(tag));
        if (pnt) {
          if (shape.Connector_P()) {
            (at1 = shape.ends()._get(0).attach());
            (at2 = shape.ends()._get(1).attach());
            at1.set_x(pnt._get(0).x);
            at1.set_y(pnt._get(0).y);
            at2.set_x(pnt._get(1).x);
            return at2.set_y(pnt._get(1).y);
          } else {
            (pos = self.$.positions._get(shape));
            if (pos) {
              pos.x().set_value(pnt.x);
              return pos.y().set_value(pnt.y);
            }
          }
        }
      }));
    }));
    (this.build_diagram = (function () {
      var self = this;
      var white, env, black;
      puts("REBUILDING");
      (white = self.$.factory.Color(255, 255, 255));
      (black = self.$.factory.Color(0, 0, 0));
      (env = (new EnsoHash({
        font: self.$.factory.Font(null, null, null, 14, "sans-serif"),
        pen: self.$.factory.Pen(1, "solid", black),
        brush: self.$.factory.Brush(black),
        nil: null
      })));
      env._set(self.$.stencil.root(), self.$.data);
      (self.$.shapeToAddress = (new EnsoHash({
        
      })));
      (self.$.shapeToModel = (new EnsoHash({
        
      })));
      (self.$.tagModelToShape = (new EnsoHash({
        
      })));
      (self.$.graphShapes = (new EnsoHash({
        
      })));
      return self.construct(self.$.stencil.body(), env, null, null, Proc.new((function (x, subid) {
        return self.set_root(x);
      })));
    }));
    (this.do_open = (function (file) {
      var self = this;
      return self.set_path(file.split("/")._get((-1)));
    }));
    (this.do_save = (function () {
      var self = this;
      var grammar, pos;
      (grammar = Load.load(S("", self.$.extension, ".grammar")));
      (pos = S("", self.$.data.factory().file_path()._get(0), ""));
      File.write((function (output) {
        return Layout.DisplayFormat.print(grammar, self.$.data, output, false);
      }), S("", pos, "-NEW"));
      return System.writeJSON(S("", pos, "-positions"), self.capture_positions());
    }));
    (this.capture_positions = (function () {
      var self = this;
      var position_map;
      (position_map = System.JSHASH());
      position_map._set("*VERSION*", 2);
      self.$.graphShapes.each((function (tag, shape) {
        var h1, h2, hash, pos, at1, at2;
        if (shape.Connector_P()) {
          (at1 = shape.ends()._get(0).attach());
          (at2 = shape.ends()._get(1).attach());
          (h1 = System.JSHASH());
          (h2 = System.JSHASH());
          (h1.x = at1.x());
          (h1.y = at1.y());
          (h2.x = at2.x());
          (h2.y = at2.y());
          return position_map._set(tag, [h1, h2]);
        } else {
          (pos = self.position_fixed(shape));
          (hash = System.JSHASH());
          (hash.x = pos.x());
          (hash.y = pos.y());
          return position_map._set(tag, hash);
        }
      }));
      return position_map;
    }));
    (this.on_double_click = (function (e) {
      var self = this;
      var text, address;
      self.clear_selection();
      (text = self.find("Text?", e));
      if ((text && text.editable())) {
        (address = self.$.shapeToAddress._get(text));
        if (address) {
          return self.edit_address(address, text);
        }
      }
    }));
    (this.edit_address = (function (address, shape) {
      var self = this;
      var pop, r;
      if (address.type().Primitive_P()) { 
        return (self.$.selection = TextEditSelection.new(self, shape, address)); 
      } 
      else {
             (pop = self.Menu().new());
             self.find_all_objects(self.$.data, address.field().type((function (obj) {
               var name;
               (name = self.ObjectKey(obj));
               return self.add_menu2(pop, name, self.name((function (e) {
                 address.set_value(obj);
                 return shape.set_string(name);
               })));
             })));
             (r = self.boundary_fixed(shape));
             return self.popup_menu(pop, r.x(), r.y());
           }
    }));
    (this.on_right_down = (function (pnt) {
      var self = this;
      var remote, m, menuItem, actions, menu;
      (actions = (new EnsoHash({
        
      })));
      self.find((function (part) {
        if (self.$.actions._get(part)) {
          (actions = actions.merge(self.$.actions._get(part)));
        }
        return false;
      }), pnt);
      if ((actions != (new EnsoHash({
        
      })))) {
        (remote = self.require("remote"));
        (menu = remote.require("menu"));
        (menuItem = remote.require("menu-item"));
        (m = menu.new());
        actions.each((function (name, action) {
          return m.append(self.MenuItem().new((new EnsoHash({
            label: name,
            click: action
          }))));
        }));
        return self.window().addEventListener((function (e) {
          e.preventDefault();
          return m.popup(remote.getCurrentWindow());
        }), "contextmenu");
      }
    }));
    (this.on_export = (function () {
      var self = this;
      var grammar;
      (grammar = Load.load("diagram.grammar"));
      return File.write((function (output) {
        return Layout.DisplayFormat.print(grammar, self.$.root, output, false);
      }), S("", self.$.path, "-diagram"));
    }));
    (this.add_action = (function (block, shape, name) {
      var self = this;
      if ((!self.$.actions._get(shape))) {
        self.$.actions._set(shape, (new EnsoHash({
          
        })));
      }
      return self.$.actions._get(shape)._set(name, block);
    }));
    (this.construct = (function (stencil, env, container, id, proc) {
      var self = this;
      return self.send(S("construct", stencil.schema_class().name(), ""), stencil, env, container, id, proc);
    }));
    (this.make_styles = (function (stencil, shape, env) {
      var self = this;
      var newEnv, font, pen, brush;
      (font = null);
      (pen = null);
      (brush = null);
      (newEnv = env.clone());
      stencil.props().each((function (prop) {
        var val;
        (val = self.eval(prop.exp(), newEnv));
        switch ((function () {
          return Renderexp.render(prop.loc());
        })()) {
          case "fill.color":
           if ((!brush)) {
             newEnv._set("brush", (brush = env._get("brush")._clone()));
           }
           return brush.set_color(val);
          case "line.color":
           if ((!pen)) {
             newEnv._set("pen", (pen = env._get("pen")._clone()));
           }
           return pen.set_color(val);
          case "line.width":
           if ((!pen)) {
             newEnv._set("pen", (pen = env._get("pen")._clone()));
           }
           return pen.set_width(val);
          case "font.color":
           if ((!font)) {
             newEnv._set("font", (font = env._get("font")._clone()));
           }
           return font.set_color(val);
          case "font.family":
           if ((!font)) {
             newEnv._set("font", (font = env._get("font")._clone()));
           }
           return font.set_family(val);
          case "font.variant":
           if ((!font)) {
             newEnv._set("font", (font = env._get("font")._clone()));
           }
           return font.set_variant(val);
          case "font.style":
           if ((!font)) {
             newEnv._set("font", (font = env._get("font")._clone()));
           }
           return font.set_style(val);
          case "font.weight":
           if ((!font)) {
             newEnv._set("font", (font = env._get("font")._clone()));
           }
           return font.set_weight(val);
          case "font.size":
           if ((!font)) {
             newEnv._set("font", (font = env._get("font")._clone()));
           }
           return font.set_size(val);
        }
            
      }));
      if (font) {
        shape.styles().push(font);
      }
      if (pen) {
        shape.styles().push(pen);
      }
      if (brush) {
        return shape.styles().push(brush);
      }
    }));
    (this.constructAlt = (function (obj, env, container, id, proc) {
      var self = this;
      return obj.alts().find((function (alt) {
        return self.construct(alt, env, container, id, proc);
      }));
    }));
    (this.constructEAssign = (function (obj, env, container, id, proc) {
      var self = this;
      var nenv;
      (nenv = env.clone());
      self.lvalue(obj.var(), nenv).set_value(self.eval(obj.val(), nenv));
      return self.construct(obj.body(), nenv, container, id, proc);
    }));
    (this.constructEImport = (function (obj, env, container, id, proc) {
      var self = this;
    }));
    (this.constructEFor = (function (obj, env, container, id, proc) {
      var self = this;
      var shape, f, is_traversal, action, lhs, source, nenv;
      (source = self.eval(obj.list(), env));
      (is_traversal = false);
      if (obj.list().EField_P()) {
        (lhs = self.eval(obj.list().e(), env));
        (f = lhs.schema_class().all_fields()._get(obj.list().fname()));
        if ((!f)) {
          self.raise(S("MISSING ", obj.list().fname(), " on ", lhs.schema_class(), ""));
        }
        (is_traversal = f.traversal());
      }
      (nenv = env.clone());
      source.each_with_index((function (v, i) {
        var loc_name, newId;
        nenv._set(obj.var(), v);
        if (obj.index()) {
          nenv._set(obj.index(), i);
        }
        if (v.schema_class().key()) {
          (loc_name = v._get(v.schema_class().key().name()));
          if (id) { 
            (newId = S("", id, ".", loc_name, "")); 
          }
          else { 
            (newId = loc_name);
          }
        }
        else {
          (newId = id);
        }
        return self.construct(obj.body(), nenv, container, newId, Proc.new((function (shape, subid) {
          var action;
          if (obj.label()) {
            (action = (is_traversal ? "Delete" : "Remove"));
            self.add_action((function () {
              if (is_traversal) { 
                return v.delete_C(); 
              }
              else { 
                return self.addr().set_value(null);
              }
            }), shape, S("", action, " ", obj.label(), ""));
          }
          return proc(shape, subid);
        })));
      }));
      if (obj.label()) {
        (action = (is_traversal ? "Create" : "Add"));
        try {(shape = self.$.tagModelToShape._get(self.addr().object().name()));
             
        }
        catch (caught$9429) {
          
        }
        if ((!shape)) {
          (shape = container);
        }
        return self.add_action((function () {
          var factory;
          (factory = self.address().object().factory());
          (obj = factory._get(self.address().type().name()));
          return obj.schema_class().fields().each((function (field) {
            if (((field.key() && field.type().Primitive_P()) && (field.type().name() == "str"))) { 
              obj._set(field.name(), S("<", field.name(), ">")); 
            }
            else { 
              if ((((!field.optional()) && (!field.type().Primitive_P())) && (!(field.inverse() && field.inverse().traversal())))) { 
                obj._set(field.name(), self.find_default_object(self.$.data, field.type())); 
              } 
              else {
                   }
            }
            return self.address().value().push(obj);
          }));
        }), shape, S("", action, " ", obj.label(), ""));
      }
    }));
    (this.find_default_object = (function (scan, type) {
      var self = this;
      return self.catch((function () {
        self.find_all_objects((function (x) {
          return self.throw("FoundObject", x);
        }), scan, type);
      }), "FoundObject");
    }));
    (this.find_all_objects = (function (block, scan, type) {
      var self = this;
      if (scan) {
        if (self.Subclass_P(scan.schema_class(), type)) {
          block(scan);
        }
        return scan.schema_class().fields().each((function (field) {
          if (field.traversal()) {
            if (field.many()) { 
              return scan._get(field.name()).each((function (x) {
                return self.find_all_objects(block, x, type);
              })); 
            }
            else { 
              return self.find_all_objects(block, scan._get(field.name()), type);
            }
          }
        }));
      }
    }));
    (this.constructEIf = (function (obj, env, container, id, proc) {
      var self = this;
      var test;
      (test = self.eval(obj.cond(), env));
      if (test) { 
        return self.construct(obj.body(), env, container, id, proc); 
      }
      else { 
        if ((!(obj.body2() == null))) { 
          return self.construct(obj.body2(), env, container, id, proc); 
        } 
        else {
             }
      }
    }));
    (this.constructEBlock = (function (obj, env, container, id, proc) {
      var self = this;
      return obj.body().each((function (command) {
        return self.construct(command, env, container, id, proc);
      }));
    }));
    (this.constructLabel = (function (obj, env, container, id, proc) {
      var self = this;
      return self.construct(obj.body(), env, container, id, Proc.new((function (shape, subid) {
        var tag;
        (tag = self.evallabel(obj.label(), env));
        self.$.tagModelToShape._set(tag._path(), shape);
        return proc(shape, subid);
      })));
    }));
    (this.evallabel = (function (label, env) {
      var self = this;
      var obj;
      return (obj = self.eval(label, env));
    }));
    (this.constructContainer = (function (obj, env, container, id, proc) {
      var self = this;
      var group;
      if ((obj.direction() == 4)) { 
        return obj.items().each((function (item) {
          return self.construct(item, env, container, id, proc);
        })); 
      } 
      else {
             (group = self.$.factory.Container());
             group.set_direction(obj.direction());
             obj.items().each((function (item) {
               return self.construct(item, env, group, id, Proc.new((function (x, subid) {
                 group.items().push(x);
                 if ((obj.direction() == 3)) {
                   return self.$.graphShapes._set(subid, x);
                 }
               })));
             }));
             self.make_styles(obj, group, env);
             if (proc) {
               return proc(group, id);
             }
           }
    }));
    (this.constructText = (function (obj, env, container, id, proc) {
      var self = this;
      var val, text, addr;
      (val = self.eval(obj.string(), env));
      (addr = null);
      (text = self.$.factory.Text());
      text.set_string(val.to_s());
      text.set_editable(obj.editable());
      self.make_styles(obj, text, env);
      if (addr) {
        self.$.shapeToAddress._set(text, addr);
      }
      return proc(text, id);
    }));
    (this.constructShape = (function (obj, env, container, id, proc) {
      var self = this;
      var shape;
      (shape = self.$.factory.Shape());
      shape.set_kind(obj.kind());
      self.construct(obj.content(), env, shape, null, Proc.new((function (x, subid) {
        if (shape.content()) {
          self.error("Shape can only have one element");
        }
        return shape.set_content(x);
      })));
      self.make_styles(obj, shape, env);
      return proc(shape, id);
    }));
    (this.makeLabel = (function (exp, env) {
      var self = this;
      var label, labelStr;
      (labelStr = self.eval(exp, env));
      if (labelStr) {
        (label = self.$.factory.Text());
        label.set_string(labelStr);
        label.set_editable(false);
        return label;
      }
    }));
    (this.constructConnector = (function (obj, env, container, id, proc) {
      var self = this;
      var ptemp, i, conn, info, label, cend;
      (conn = self.$.factory.Connector());
      if ((obj.ends()._get(0).label() == obj.ends()._get(1).label())) { 
        (ptemp = [self.$.factory.EdgePos(1, 0.5), self.$.factory.EdgePos(1, 0.75)]); 
      }
      else { 
        (ptemp = [self.$.factory.EdgePos(0.5, 1), self.$.factory.EdgePos(0.5, 0)]);
      }
      (i = 0);
      (info = null);
      (label = null);
      (cend = null);
      obj.ends().each((function (e) {
        var other_label, x;
        (label = ((e.label() == null) ? null : self.makeLabel(e.label(), env)));
        (other_label = ((e.other_label() == null) ? null : self.makeLabel(e.other_label(), env)));
        (cend = self.$.factory.ConnectorEnd(e.arrow(), label, other_label));
        (info = self.evallabel(e.part(), env));
        (x = self.$.tagModelToShape._get(info._path()));
        if ((x == null)) {
          self.fail(S("Shape ", info._path(), " does not exist in ", self.$.tagModelToShape, ""));
        }
        cend.set_to(x);
        cend.set_attach(ptemp._get(i));
        (i = (i + 1));
        return conn.ends().push(cend);
      }));
      self.make_styles(obj, conn, env);
      return proc(conn, id);
    }));
    (this.lvalue = (function (exp, env) {
      var self = this;
      return Lvalue.lvalue(exp, (new EnsoHash({
        env: env,
        factory: self.$.factory
      })));
    }));
    (this.eval = (function (obj, env) {
      var self = this;
      var interp;
      (interp = Stencil.EvalColorC.new(self));
      return interp.dynamic_bind((function () {
        return interp.eval(obj);
      }), (new EnsoHash({
        env: env
      })));
    }));
  }));
  var EvalColorC = MakeClass("EvalColorC", null, [Eval.EvalExpr], (function () {
  }), (function (super$) {
    (this.initialize = (function (d) {
      var self = this;
      return (self.$.diagram = d);
    }));
    (this.eval_Color = (function (this_V) {
      var self = this;
      return self.$.diagram.factory().Color(self.eval(this_V.r()), self.eval(this_V.g()), self.eval(this_V.b()));
    }));
  }));
  var TextEditSelection = MakeClass("TextEditSelection", null, [], (function () {
  }), (function (super$) {
    (this.initialize = (function (diagram, edit, address) {
      var self = this;
      var n, style, r, extraWidth;
      (self.$.address = address);
      (self.$.diagram = diagram);
      (self.$.edit_selection = edit);
      (r = diagram.boundary_fixed(self.$.edit_selection));
      (n = 3);
      (extraWidth = 10);
      (self.$.edit_control = self.TextCtrl().new(diagram, 0, "", (r.x() - n), (r.y() - n), ((r.w() + (2 * n)) + extraWidth), (r.h() + (2 * n)), 0));
      (style = self.TextAttr().new());
      style.set_text_colour(diagram.makeColor(diagram.foreground()));
      style.set_font(diagram.makeFont(diagram.font()));
      self.$.edit_control.set_default_style(style);
      self.$.edit_control.append_text(self.$.edit_selection.string());
      self.$.edit_control.show();
      return self.$.edit_control.set_focus();
    }));
    (this.clear = (function () {
      var self = this;
      var new_text;
      (new_text = self.$.edit_control.get_value());
      self.$.address.set_value(new_text);
      self.$.edit_selection.set_string(new_text);
      self.$.edit_control.destroy();
      return null;
    }));
  }));
  (Stencil = {
    StencilFrame: StencilFrame,
    TextEditSelection: TextEditSelection,
    EvalColorC: EvalColorC
  });
  return Stencil;
}));