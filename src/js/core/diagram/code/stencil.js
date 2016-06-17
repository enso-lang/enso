define([
  "core/diagram/code/diagram",
  "core/schema/tools/print",
  "core/system/load/load",
  "core/system/library/schema",
  "core/expr/code/eval",
  "core/expr/code/lvalue",
  "core/semantics/code/interpreter",
  "core/system/utils/paths"
],
function(Diagram, Print, Load, Schema, Eval, Lvalue, Interpreter, Paths) {
  var Stencil ;

  var StencilFrame = MakeClass("StencilFrame", Diagram.DiagramFrame, [],
    function() {
    },
    function(super$) {
      this.selection = function() { return this.$.selection };

      this.initialize = function(win, canvas, context, path) {
        var self = this; 
        if (path === undefined) path = null;
        super$.initialize.call(self, win, canvas, context, "Model Editor");
        self.$.actions = new EnsoHash ({ });
        if (path) {
          return self.set_path(path);
        }
      };

      this.set_stencil = function(val) { this.$.stencil  = val };

      this.set_path = function(path) {
        var self = this; 
        var ext;
        puts(S("Opening ", path));
        ext = path.substr(path.lastIndexOf(".") + 1);
        if (ext.size() < 2) {
          self.raise("File has no extension");
        }
        self.$.path = path;
        return self.setup(ext, Load.load(self.$.path));
      };

      this.setup = function(extension, data) {
        var self = this; 
        var pos;
        self.$.extension = extension;
        self.$.stencil = Load.load(S(self.$.extension, ".stencil"));
        if (! (self.$.stencil.title() == null)) {
          self.set_title(self.$.stencil.title());
        }
        self.$.data = data;
        self.build_diagram();
        if (data.factory().file_path()._get(0)) {
          pos = S(data.factory().file_path()._get(0), "-positions");
          self.$.position_map = new EnsoHash ({ });
          if (File.exists_P(pos)) {
            return self.$.position_map = System.readJSON(pos);
          }
        }
      };

      this.rebuild_diagram = function() {
        var self = this; 
        self.capture_positions();
        return self.build_diagram();
      };

      this.build_diagram = function() {
        var self = this; 
        var white, black, env;
        puts("REBUILDING");
        white = self.$.factory.Color(255, 255, 255);
        black = self.$.factory.Color(0, 0, 0);
        env = new EnsoHash ({ font: self.$.factory.Font(null, null, null, 12, "swiss"), pen: self.$.factory.Pen(1, "solid", black), brush: self.$.factory.Brush(white), nil: null });
        env._set(self.$.stencil.root(), self.$.data);
        self.$.shapeToAddress = new EnsoHash ({ });
        self.$.shapeToModel = new EnsoHash ({ });
        self.$.shapeToTag = new EnsoHash ({ });
        self.$.tagModelToShape = new EnsoHash ({ });
        self.$.connectors = [];
        self.construct(self.$.stencil.body(), env, null, Proc.new(function(x) {
          return self.set_root(x);
        }));
        puts("DONE");
        return Print.print(self.$.root);
      };

      this.lookup_shape = function(shape) {
        var self = this; 
        return self.$.shapeToModel._get(shape);
      };

      this.setup_menus = function() {
        var self = this; 
        var file;
        super$.setup_menus.call(self, "FOO");
        file = self.menu_bar().get_menu(self.menu_bar().find_menu("File"));
        return self.add_menu(file, "&Export\\tCmd-E", "Export Diagram", "on_export");
      };

      this.on_open = function() {
        var self = this; 
        var dialog;
        dialog = FileDialog.new(self, "Choose a file", "", "", "Model files (*.*)|*.*");
        if (dialog.show_modal() == ID_OK) {
          return self.set_path(dialog.get_path());
        }
      };

      this.on_save = function() {
        var self = this; 
        var grammar;
        grammar = Loader.load(S(self.$.extension, ".grammar"));
        File.open(function(output) {
          return DisplayFormat.print(grammar, self.$.data, 80, output);
        }, S(self.$.path, "-NEW"), "w");
        return self.capture_positions();
      };

      this.capture_positions = function() {
        var self = this; 
        var size, obj_handler, connector_handler;
        self.$.position_map = new EnsoHash ({ });
        self.$.position_map._set("*VERSION*", 2);
        size = self.$.conext.size();
        self.$.position_map._set("*WINDOW*", new EnsoHash ({ x: size.get_width(), y: size.get_height() }));
        obj_handler = Proc.new(function(tag, obj, shape) {
          return self.$.position_map._set(tag, self.position(shape));
        });
        connector_handler = Proc.new(function(tag, at1, at2) {
          return self.$.position_map._set(tag, [EnsoPoint.new(at1.x(), at1.y()), EnsoPoint.new(at2.x(), at2.y())]);
        });
        return self.generate_saved_positions(obj_handler, connector_handler, 9999);
      };

      this.generate_saved_positions = function(obj_handler, connector_handler, version) {
        var self = this; 
        var label, obj, tag, ce1, ce2, obj1, obj2, k, l;
        self.$.tagModelToShape.each(function(tagObj, shape) {
          label = tagObj._get(0);
          obj = tagObj._get(1);
          try {
            if (version == 1) {
              tag = obj.name();
            } else {
              tag = S(label, ":", obj._path().to_s());
            }
            return obj_handler(tag, obj, shape);
          } catch (DUMMY) {
          }
        });
        return self.$.connectors.each(function(conn) {
          ce1 = conn.ends()._get(0);
          ce2 = conn.ends()._get(1);
          obj1 = self.$.shapeToModel._get(ce1.to());
          obj2 = self.$.shapeToModel._get(ce2.to());
          try {
            if (version == 1) {
              k = obj1.name();
              if (ce1.label()) {
                l = ce1.label().string();
              }
              tag = S(k, ".", l);
            } else {
              label = self.$.shapeToTag._get(ce1.to());
              l = S(ce1.label() && ce1.label().string(), "*", ce2.label() && ce2.label().string());
              tag = S(label, ":", obj1._path().to_s(), ":", obj2._path().to_s(), "$", l);
            }
            return connector_handler(tag, ce1.attach(), ce2.attach());
          } catch (DUMMY) {
          }
        });
      };

      this.do_constraints = function() {
        var self = this; 
        var field, parts, key, obj, pos, l, conn, pnt, obj_handler, connector_handler;
        super$.do_constraints.call(self, "FOO");
/*        self.$.position_map.each(function(key, pnt) {
          field = null;
          parts = key.split(".");
          if (parts.size() == 2) {
            key = parts._get(0);
            field = parts._get(1);
          }
          obj = self.$.labelToShape._get(key);
          if (! obj.isnil_P()) {
            if (field == null) {
              pos = self.$.positions._get(obj);
              if (! pos.isnil_P()) {
                pos.x().set_value(pnt.x());
                return pos.y().set_value(pnt.y());
              }
            } else {
              return obj.connectors().find(function(ce) {
                l = ce.label()
                  ? ce.label().string()
                  : "";
                if (field == l) {
                  conn = ce.owner();
                  conn.ends()._get(0).attach().set_x(pnt._get(0).x());
                  conn.ends()._get(0).attach().set_y(pnt._get(0).y());
                  conn.ends()._get(1).attach().set_x(pnt._get(1).x());
                  conn.ends()._get(1).attach().set_y(pnt._get(1).y());
                  return true;
                }
              });
            }
          }
        });
        if (self.$.position_map) {
          obj_handler = Proc.new(function(tag, obj, shape) {
            pos = self.$.positions._get(shape);
            pnt = self.$.position_map._get(tag);
            if (pos && pnt) {
              pos.x().set_value(pnt.x());
              return pos.y().set_value(pnt.y());
            }
          });
          connector_handler = Proc.new(function(tag, at1, at2) {
            pnt = self.$.position_map._get(tag);
            if (pnt) {
              at1.set_x(pnt._get(0).x());
              at1.set_y(pnt._get(0).y());
              at2.set_x(pnt._get(1).x());
              return at2.set_y(pnt._get(1).y());
            }
          });
          return self.generate_saved_positions(obj_handler, connector_handler, self.$.position_map._get("*VERSION*") || 1);
        }
 */
      };

      this.connection_other_end = function(ce) {
        var self = this; 
        var conn;
        conn = ce.connection();
        if (conn.ends()._get(0) == ce) {
          return conn.ends()._get(1);
        } else {
          return conn.ends()._get(0);
        }
      };

      this.on_export = function() {
        var self = this; 
        var grammar;
        grammar = Loader.load("diagram.grammar");
        return File.open(function(output) {
          return DisplayFormat.print(grammar, self.$.root, 80, output);
        }, S(self.$.path, "-diagram"), "w");
      };

      this.add_action = function(block, shape, name) {
        var self = this; 
        if (! self.$.actions._get(shape)) {
          self.$.actions._set(shape, new EnsoHash ({ }));
        }
        return self.$.actions._get(shape)._set(name, block);
      };

      this.construct = function(stencil, env, container, proc) {
        var self = this; 
        return self.send(S("construct", stencil.schema_class().name()), stencil, env, container, proc);
      };

      this.make_styles = function(stencil, shape, env) {
        var self = this; 
        var newEnv, font, pen, brush, val;
        newEnv = null;
        font = null;
        pen = null;
        brush = null;
        newEnv = env.clone();
        stencil.props().each(function(prop) {
          val = self.eval(prop.exp(), newEnv);
          switch (Interpreter(RenderExpr).render(prop.loc())) {
            case "font.size":
              if (! font) {
                newEnv._set("font", font = env._get("font")._clone());
              }
              return font.set_size(val);
            case "font.weight":
              if (! font) {
                font = newEnv._get("font") = env._get("font")._clone();
              }
              return font.set_weight(val);
            case "line.width":
              if (! pen) {
                pen = newEnv._get("pen") = env._get("pen")._clone();
              }
              return pen.set_width(val);
            case "line.color":
              if (! pen) {
                pen = newEnv._get("pen") = env._get("pen")._clone();
              }
              return pen.set_color(val);
            case "fill.color":
              if (! brush) {
                brush = newEnv._get("brush") = env._get("brush")._clone();
              }
              return brush.set_color(val);
          }
        });
        shape.styles().push(font || env._get("font"));
        shape.styles().push(pen || env._get("pen"));
        return shape.styles().push(brush || env._get("brush"));
      };

      this.constructAlt = function(this_V, env, container, proc) {
        var self = this; 
        return this_V.alts().find(function(alt) {
          return self.construct(alt, env, container, proc);
        });
      };

      this.constructEAssign = function(this_V, env, container, proc) {
        var self = this; 
        var nenv;
        nenv = env.clone();
        self.lvalue(this_V.var(), nenv).set_value(self.eval(this_V.val(), nenv));
        return self.construct(this_V.body(), nenv, container, proc);
      };

      this.constructEImport = function(this_V, env, container, proc) {
        var self = this; 
      };

      this.constructEFor = function(this_V, env, container, proc) {
        var self = this; 
        var source, is_traversal, lhs, f, nenv, action, shape, factory, obj;
        source = self.eval(this_V.list(), env);
        is_traversal = false;
        if (this_V.list().EField_P()) {
          lhs = self.eval(this_V.list().e(), env);
          f = lhs.schema_class().all_fields()._get(this_V.list().fname());
          if (! f) {
            self.raise(S("MISSING ", this_V.list().fname(), " on ", lhs.schema_class()));
          }
          is_traversal = f.traversal();
        }
        nenv = env.clone();
        source.each_with_index(function(v, i) {
          nenv._set(this_V.var(), v);
          if (this_V.index()) {
            nenv._set(this_V.index(), i);
          }
          return self.construct(this_V.body(), nenv, container, Proc.new(function(shape) {
            if (this_V.label()) {
              action = is_traversal
                ? "Delete"
                : "Remove";
              self.add_action(function() {
                if (is_traversal) {
                  v.delete_in_place();
                } else {
                  self.addr().set_value(null);
                }
                return self.rebuild_diagram();
              }, shape, S(action, " ", this_V.label()));
            }
            return proc(shape);
          }));
        });
        if (this_V.label()) {
          action = is_traversal
            ? "Create"
            : "Add";
          try {
            shape = self.$.tagModelToShape._get(self.addr().object().name());
          } catch (DUMMY) {
          }
          if (! shape) {
            shape = container;
          }
          return self.add_action(function() {
            if (! is_traversal) {
              return self.$.selection = FindByTypeSelection.new(function(x) {
                self.address().value().push(x);
                return self.rebuild_diagram();
              }, self, self.address().type());
            } else {
              factory = self.address().object().factory();
              obj = factory._get(self.address().type().name());
              obj.schema_class().fields().each(function(field) {
                if ((field.key() && field.type().Primitive_P()) && field.type().name() == "str") {
                  return obj._set(field.name(), S("<", field.name(), ">"));
                } else if ((! field.optional() && ! field.type().Primitive_P()) && ! (field.inverse() && field.inverse().traversal())) {
                  return obj._set(field.name(), self.find_default_object(self.$.data, field.type()));
                }
              });
              self.address().value().push(obj);
              return self.rebuild_diagram();
            }
          }, shape, S(action, " ", this_V.label()));
        }
      };

      this.find_default_object = function(scan, type) {
        var self = this; 
        return self.catch(function() {
          return self.find_all_objects(function(x) {
            return self.throw("FoundObject", x);
          }, scan, type);
        }, "FoundObject");
      };

      this.find_all_objects = function(block, scan, type) {
        var self = this; 
        if (scan) {
          if (Subclass_P(scan.schema_class(), type)) {
            block(scan);
          }
          return scan.schema_class().fields().each(function(field) {
            if (field.traversal()) {
              if (field.many()) {
                return scan._get(field.name()).each(function(x) {
                  return self.find_all_objects(block, x, type);
                });
              } else {
                return self.find_all_objects(block, scan._get(field.name()), type);
              }
            }
          });
        }
      };

      this.constructEIf = function(this_V, env, container, proc) {
        var self = this; 
        var test;
        test = self.eval(this_V.cond(), env);
        if (test) {
          return self.construct(this_V.body(), env, container, proc);
        } else if (! (this_V.body2() == null)) {
          return self.construct(this_V.body2(), env, container, proc);
        }
      };

      this.constructEBlock = function(this_V, env, container, proc) {
        var self = this; 
        return this_V.body().each(function(command) {
          return self.construct(command, env, container, proc);
        });
      };

      this.constructLabel = function(this_V, env, container, proc) {
        var self = this; 
        var info, tag, obj;
        return self.construct(this_V.body(), env, container, Proc.new(function(shape) {
          info = self.evallabel(this_V.label(), env);
          tag = info._get(0);
          obj = info._get(1);
          self.$.tagModelToShape._set([tag, obj], shape);
          self.$.shapeToModel._set(shape, obj);
          self.$.shapeToTag._set(shape, tag);
          return proc(shape);
        }));
      };

      this.evallabel = function(label, env) {
        var self = this; 
        var tag, label, obj;
        tag = "default";
        if (label.ESubscript_P()) {
          tag = label.e();
          label = label.sub();
          if (! tag.Var_P()) {
            self.raise("foo");
          }
          tag = tag.name();
        }
        obj = self.eval(label, env);
        return [tag, obj];
      };

      this.constructContainer = function(this_V, env, container, proc) {
        var self = this; 
        var group;
        if (this_V.direction() == 4) {
          return this_V.items().each(function(item) {
            return self.construct(item, env, container, proc);
          });
        } else {
          group = self.$.factory.Container();
          group.set_direction(this_V.direction());
          this_V.items().each(function(item) {
            return self.construct(item, env, group, Proc.new(function(x) {
              return group.items().push(x);
            }));
          });
          self.make_styles(this_V, group, env);
          if (proc) {
            return proc(group);
          }
        }
      };

      this.constructText = function(this_V, env, container, proc) {
        var self = this; 
        var val, addr, text;
        val = self.eval(this_V.string(), env);
        addr = null;
        text = self.$.factory.Text();
        text.set_string(val.to_s());
        text.set_editable(this_V.editable());
        self.make_styles(this_V, text, env);
        if (addr) {
          self.$.shapeToAddress._set(text, addr);
        }
        return proc(text);
      };

      this.constructShape = function(this_V, env, container, proc) {
        var self = this; 
        var shape;
        shape = self.$.factory.Shape();
        shape.set_kind(this_V.kind());
        self.construct(this_V.content(), env, shape, Proc.new(function(x) {
          if (shape.content()) {
            self.error("Shape can only have one element");
          }
          return shape.set_content(x);
        }));
        self.make_styles(this_V, shape, env);
        return proc(shape);
      };

      this.makeLabel = function(exp, env) {
        var self = this; 
        var labelStr, label;
        labelStr = self.eval(exp, env);
        if (labelStr) {
          label = self.$.factory.Text();
          label.set_string(labelStr);
          label.set_editable(false);
          return label;
        }
      };

      this.constructConnector = function(this_V, env, container, proc) {
        var self = this; 
        var conn, ptemp, i, label, other_label, de, info, tag, obj, x;
        conn = self.$.factory.Connector();
        self.$.connectors.push(conn);
        ptemp = [self.$.factory.EdgePos(0.5, 1), self.$.factory.EdgePos(0.5, 0)];
        i = 0;
        this_V.ends().each(function(e) {
          label = e.label() == null
            ? null
            : self.makeLabel(e.label(), env);
          other_label = e.other_label() == null
            ? null
            : self.makeLabel(e.other_label(), env);
          de = self.$.factory.ConnectorEnd(e.arrow(), label, other_label);
          info = self.evallabel(e.part(), env);
          tag = info._get(0);
          obj = info._get(1);
          x = self.$.tagModelToShape._get([tag, obj]);
          if (x == null) {
            self.fail(S("Shape ", [tag, obj], " does not exist in ", self.$.tagModelToShape));
          }
          de.set_to(x);
          de.set_attach(ptemp._get(i));
          i = i + 1;
          return conn.ends().push(de);
        });
        self.make_styles(this_V, conn, env);
        return proc(conn);
      };

      this.eval = function(exp, env) {
        var self = this; 
        return Eval.eval(exp, new EnsoHash ({ env: env }));
      };

      this.lvalue = function(exp, env) {
        var self = this; 
        if (self.$.lval == null) {
          self.$.lval = Interpreter(LValueExpr);
        }
        return self.$.lval.lvalue(exp, new EnsoHash ({ env: env, factory: self.$.factory }));
      };
    });

  var TextEditSelection = MakeClass("TextEditSelection", null, [],
    function() {
    },
    function(super$) {
      this.initialize = function(diagram, edit, address) {
        var self = this; 
        var r, n, extraWidth, style;
        self.$.address = address;
        self.$.diagram = diagram;
        self.$.edit_selection = edit;
        r = diagram.boundary(self.$.edit_selection);
        n = 3;
        extraWidth = 10;
        self.$.edit_control = Wx.TextCtrl.new(diagram, 0, "", Point.new(r.x() - n, r.y() - n), Size.new((r.w() + 2 * n) + extraWidth, r.h() + 2 * n), 0);
        style = Wx.TextAttr.new();
        style.set_text_colour(diagram.makeColor(diagram.foreground()));
        style.set_font(diagram.makeFont(diagram.font()));
        self.$.edit_control.set_default_style(style);
        self.$.edit_control.append_text(self.$.edit_selection.string());
        self.$.edit_control.show();
        return self.$.edit_control.set_focus();
      };

      this.clear = function() {
        var self = this; 
        var new_text;
        new_text = self.$.edit_control.get_value();
        self.$.address.set_value(new_text);
        self.$.edit_selection.set_string(new_text);
        self.$.edit_control.destroy();
        return null;
      };

      this.on_mouse_down = function(e) {
        var self = this; 
      };

      this.on_move = function(e, down) {
        var self = this; 
      };

      this.on_paint = function(dc) {
        var self = this; 
      };

      this.is_selected = function(part) {
        var self = this; 
      };
    });

  var FindByTypeSelection = MakeClass("FindByTypeSelection", null, [],
    function() {
    },
    function(super$) {
      this.initialize = function(action, diagram, kind) {
        var self = this; 
        self.$.diagram = diagram;
        self.$.part = null;
        self.$.kind = kind;
        return self.$.action = action;
      };

      this.on_move = function(e, down) {
        var self = this; 
        var obj;
        return self.$.part = self.$.diagram.find(function(shape) {
          obj = self.$.diagram.lookup_shape(shape);
          return obj && Subclass_P(obj.schema_class(), self.$.kind);
        }, e);
      };

      this.is_selected = function(check) {
        var self = this; 
        return self.$.part == check;
      };

      this.on_paint = function(dc) {
        var self = this; 
      };

      this.on_mouse_down = function(e) {
        var self = this; 
        if (self.$.part) {
          self.$.action(self.$.diagram.lookup_shape(self.$.part));
        }
        return "cancel";
      };

      this.clear = function() {
        var self = this; 
      };
    });

  Stencil = {
    RunStencilApp: function(path) {
      var self = this; 
      if (path === undefined) path = ARGV._get(0);
    },

    StencilFrame: StencilFrame,
    TextEditSelection: TextEditSelection,
    FindByTypeSelection: FindByTypeSelection,

  };
  return Stencil;
})
