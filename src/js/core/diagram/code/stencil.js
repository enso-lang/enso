define(["core/diagram/code/diagram", "core/schema/tools/print", "core/system/load/load", "core/grammar/render/layout", "core/system/library/schema", "core/expr/code/eval", "core/expr/code/lvalue", "core/semantics/code/interpreter", "core/expr/code/renderexp", "core/expr/code/env"], (function (Diagram, Print, Load, Layout, Schema, Eval, Lvalue, Interpreter, Renderexp, Env) {
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
        (self.$.win.document().title = self.$.stencil.title());
      }
      (self.$.data = data);
      self.$.data.finalize();
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
            (pos = self.$.positions._get(shape._id()));
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
      (env = Env.HashEnv.new());
      env._set("font", self.$.factory.Font(null, null, null, 14, "sans-serif"));
      env._set("pen", self.$.factory.Pen(1, "solid", black));
      env._set("brush", self.$.factory.Brush(black));
      env._set("align", self.$.factory.Align("left"));
      env._set(self.$.stencil.root(), self.$.data);
      (self.$.shapeToAddress = (new EnsoHash({
        
      })));
      (self.$.shapeToModel = (new EnsoHash({
        
      })));
      (self.$.tagModelToShape = (new EnsoHash({
        
      })));
      (self.$.graphShapes = (new EnsoHash({
        
      })));
      self.$.stencil.finalize();
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
    (this.on_double_click = (function () {
      var self = this;
      return Proc.new((function (e) {
        var text, address, pnt;
        (pnt = self.getCursorPosition(e));
        (text = self.find_in_ui((function (v) {
          return (v.schema_class().name() == "Text");
        }), pnt));
        if (text) {
          (address = self.$.shapeToAddress._get(text));
          if (address) {
            return self.edit_address(address, text);
          }
        }
      }));
    }));
    (this.edit_address = (function (address, shape) {
      var self = this;
      var actions;
      if (address.type().Primitive_P()) { 
        return (self.$.selection = TextEditSelection.new(self, shape, address)); 
      } 
      else {
             (actions = System.JSHASH());
             self.find_all_objects(self.$.data, address.index().type((function (obj) {
               var name, action;
               (name = self.ObjectKey(obj));
               (action = Proc.new((function (e) {
                 address.set_value(obj);
                 return shape.set_string(name);
               })));
               return actions._set(name, action);
             })));
             if ((actions != System.JSHASH())) {
               puts(S("MENU ", actions, ""));
               return System.popupMenu(actions);
             }
           }
    }));
    (this.on_right_down = (function (pnt) {
      var self = this;
      var actions;
      (actions = []);
      self.find_in_ui((function (part, container) {
        puts(S("ITEM ", part._id(), "  ", self.$.actions._get(part._id()), ""));
        if (self.$.actions._get(part._id())) {
          actions.push(self.$.actions._get(part._id()));
        }
        return false;
      }), pnt);
      puts(S("ACTIONS ", actions, ""));
      return System.popupMenu(actions);
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
      if ((!self.$.actions._get(shape._id()))) {
        self.$.actions._set(shape._id(), System.JSHASH());
      }
      return self.$.actions._get(shape._id())._set(name, block);
    }));
    (this.construct = (function (stencil, env, container, id, proc) {
      var self = this;
      return self.send(S("construct", stencil.schema_class().name(), ""), stencil, env, container, id, proc);
    }));
    (this.make_styles = (function (stencil, shape, env) {
      var self = this;
      var align, newEnv, font, pen, brush;
      (font = null);
      (pen = null);
      (brush = null);
      (align = null);
      (newEnv = env.clone());
      stencil.props().each((function (prop) {
        var val;
        (val = self.eval(prop.exp(), newEnv));
        switch ((function () {
          return Renderexp.render(prop.loc());
        })()) {
          case "fill.color":
           if ((!brush)) {
             return newEnv._set("brush", (brush = self.$.factory.Brush(val)));
           }
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
          case "align":
           if ((!align)) {
             return newEnv._set("align", (align = self.$.factory.Align(val)));
           }
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
        shape.styles().push(brush);
      }
      if (align) {
        return shape.styles().push(align);
      }
    }));
    (this.constructAlt = (function (obj, env, container, id, proc) {
      var self = this;
      return obj.alts().find_first((function (alt) {
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
    (this.minimum = (function (x, y) {
      var self = this;
      if ((x < y)) { 
        return x; 
      }
      else { 
        return y;
      }
    }));
    (this.maximum = (function (x, y) {
      var self = this;
      if ((x > y)) { 
        return x; 
      }
      else { 
        return y;
      }
    }));
    (this.constructGrid = (function (grid, env, container, id, proc) {
      var self = this;
      var c, colMax, rowMin, rowMax, dgrid, r, colMin;
      (self.$.col_index = (new EnsoHash({
        
      })));
      (self.$.top_data = []);
      (self.$.row_index = (new EnsoHash({
        
      })));
      (self.$.side_data = []);
      (dgrid = self.$.factory.Grid());
      grid.axes().each((function (axis) {
        switch ((function () {
          return axis.direction();
        })()) {
          case "body":
           (self.$.grid_label_type = "reference");
           return self.construct(axis.source(), env, dgrid, id, Proc.new((function (item, ni) {
             var g;
             (g = self.$.factory.Positional());
             g.set_row(self.$.global_rowNum);
             g.set_col(self.$.global_colNum);
             g.set_contents(item);
             return dgrid.items().push(g);
           })));
          case "rows":
           (self.$.grid_label_type = "define");
           return self.construct(axis.source(), env, dgrid, id, Proc.new((function (item, ni) {
             return self.$.side_data._get((self.$.side_data.size() - 1)).push(item);
           })));
          case "columns":
           (self.$.grid_label_type = "define");
           return self.construct(axis.source(), env, dgrid, id, Proc.new((function (item, ni) {
             return self.$.top_data._get((self.$.top_data.size() - 1)).push(item);
           })));
        }
            
      }));
      (c = 0);
      self.$.top_data.each((function (td) {
        var r;
        (r = (-td.size()));
        td.each((function (item) {
          var g;
          (g = self.$.factory.Positional());
          g.set_row(r);
          g.set_col(c);
          g.set_contents(item);
          dgrid.tops().push(g);
          return (r = (r + 1));
        }));
        return (c = (c + 1));
      }));
      (r = 0);
      self.$.side_data.each((function (sd) {
        (c = (-sd.size()));
        sd.each((function (item) {
          var g;
          (g = self.$.factory.Positional());
          g.set_row(r);
          g.set_col(c);
          g.set_contents(item);
          dgrid.sides().push(g);
          return (c = (c + 1));
        }));
        return (r = (r + 1));
      }));
      (colMax = (-100000));
      (colMin = 100000);
      (rowMax = (-100000));
      (rowMin = 100000);
      [dgrid.tops(), dgrid.sides(), dgrid.items()].each((function (group) {
        return group.each((function (item) {
          (colMax = self.maximum(colMax, item.col()));
          (rowMax = self.maximum(rowMax, item.row()));
          (colMin = self.minimum(colMin, item.col()));
          return (rowMin = self.minimum(rowMin, item.row()));
        }));
      }));
      [dgrid.tops(), dgrid.sides(), dgrid.items()].each((function (group) {
        return group.each((function (item) {
          item.set_col((item.col() - colMin));
          return item.set_row((item.row() - rowMin));
        }));
      }));
      dgrid.set_colNum(((colMax - colMin) + 1));
      dgrid.set_rowNum(((rowMax - rowMin) + 1));
      return proc(dgrid, id);
    }));
    (this.constructEFor = (function (efor, env, container, id, proc) {
      var self = this;
      var shape, f, is_traversal, address, action, lhs, source, nenv;
      (source = self.eval(efor.list(), env));
      (address = self.lvalue(efor.list(), env));
      (is_traversal = false);
      if (efor.list().EField_P()) {
        (lhs = self.eval(efor.list().e(), env));
        (f = lhs.schema_class().all_fields()._get(efor.list().fname()));
        if ((!f)) {
          self.raise(S("MISSING ", efor.list().fname(), " on ", lhs.schema_class(), ""));
        }
        (is_traversal = f.traversal());
      }
      (nenv = env.clone());
      source.each_with_index((function (v, i) {
        var loc_name, newId;
        nenv._set(efor.var(), v);
        if (efor.index()) {
          nenv._set(efor.index(), i);
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
        return self.construct(efor.body(), nenv, container, newId, Proc.new((function (shape, subid) {
          var action;
          if (efor.label()) {
            (action = (is_traversal ? "Delete" : "Remove"));
            self.add_action((function () {
              if (is_traversal) { 
                return v.delete_C(); 
              }
              else { 
                return self.addr().set_value(null);
              }
            }), container, S("", action, " ", efor.label(), ""));
          }
          return proc(shape, subid, v);
        })));
      }));
      if (efor.label()) {
        (action = (is_traversal ? "Create" : "Add"));
        (shape = container);
        return self.add_action((function () {
          var factory, obj;
          (factory = self.$.data.factory());
          (obj = factory._get(address.type().name()));
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
            return address.value().push(obj);
          }));
        }), shape, S("", action, " ", efor.label(), ""));
      }
    }));
    (this.find_default_object = (function (scan, type) {
      var self = this;
      return self.find_all_objects((function (x) {
        return scan;
      }), scan, type);
    }));
    (this.find_all_objects = (function (block, scan, type) {
      var self = this;
      if (scan) {
        if (Schema.subclass_P(scan.schema_class(), type)) {
          if (block(scan)) { 
            return scan; 
          }
          else { 
            return scan.schema_class().fields().each((function (field) {
              if (field.traversal()) {
                if (field.many()) { 
                  return scan._get(field.name()).find_first((function (x) {
                    return self.find_all_objects(block, x, type);
                  })); 
                }
                else { 
                  return self.find_all_objects(block, scan._get(field.name()), type);
                }
              }
            }));
          }
        }
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
      var target;
      if (obj.body()) { 
        return self.construct(obj.body(), env, container, id, Proc.new((function (shape, subid) {
          var target;
          (target = self.evallabel(obj.label(), env));
          self.$.tagModelToShape._set(target._path(), shape);
          return proc(shape, subid);
        }))); 
      } 
      else {
             (target = self.evallabel(obj.label(), env));
             switch ((function () {
               return self.$.grid_label_type;
             })()) {
               case "reference":
                switch ((function () {
                  return obj.type();
                })()) {
                  case "row":
                   return (self.$.global_rowNum = self.$.row_index._get(target));
                  case "col":
                   return (self.$.global_colNum = self.$.col_index._get(target));
                }
                    
               case "define":
                switch ((function () {
                  return obj.type();
                })()) {
                  case "row":
                   self.$.side_data.push([]);
                   return self.$.row_index._set(target, (self.$.side_data.size() - 1));
                  case "col":
                   self.$.top_data.push([]);
                   return self.$.col_index._set(target, (self.$.top_data.size() - 1));
                }
                    
             }
                 
           }
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
                 if (((obj.direction() == 3) || (obj.direction() == 5))) {
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
    (this.constructPage = (function (obj, env, container, id, proc) {
      var self = this;
      var page;
      (page = self.$.factory.Page());
      page.set_name(obj.name());
      self.construct(obj.part(), env, container, id, Proc.new((function (sub) {
        if (obj.content()) {
          self.raise(S("two content items in a page ", obj.content().to_s(), ""));
        }
        return obj.set_content(sub);
      })));
      if (proc) {
        return proc(page, id);
      }
    }));
    (this.constructText = (function (obj, env, container, id, proc) {
      var self = this;
      var val, text, addr;
      (val = self.eval(obj.string(), env));
      (addr = self.lvalue(obj.string(), env));
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
        var x;
        (label = ((e.label() == null) ? null : self.makeLabel(e.label(), env)));
        (cend = self.$.factory.ConnectorEnd(e.arrow(), label));
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
        env: env
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
  var TextEditSelection = MakeClass("TextEditSelection", Diagram.Selection, [], (function () {
  }), (function (super$) {
    (this.initialize = (function (diagram, shape, address) {
      var self = this;
      var n, r, extraWidth;
      (self.$.address = address);
      (self.$.diagram = diagram);
      (self.$.edit_selection = shape);
      (r = diagram.boundary_fixed(shape));
      (n = 2);
      (extraWidth = 5);
      (diagram.input().style.left = ((r.x() - 1) + "px"));
      (diagram.input().style.top = ((r.y() - 2) + "px"));
      (diagram.input().style.width = (((r.w() + n) + extraWidth) + "px"));
      (diagram.input().style.height = ((r.h() + n) + "px"));
      (diagram.input().value = shape.string());
      return diagram.input().focus();
    }));
    (this.clear = (function () {
      var self = this;
      var new_text, pos;
      (new_text = self.$.diagram.input().value);
      self.$.address.set_value(new_text);
      self.$.edit_selection.set_string(new_text);
      (self.$.diagram.input().style.left = "-100px");
      (self.$.diagram.input().style.top = "-100px");
      (pos = self.$.diagram.boundary(self.$.edit_selection));
      self.$.diagram.constrainText(self.$.edit_selection, pos.x(), pos.y(), pos.w(), pos.h());
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