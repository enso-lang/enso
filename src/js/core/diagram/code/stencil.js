'use strict'

//// Stencil ////

var cwd = process.cwd() + '/';
var Diagram = require(cwd + "core/diagram/code/diagram.js");
var Print = require(cwd + "core/schema/tools/print.js");
var Load = require(cwd + "core/system/load/load.js");
var Layout = require(cwd + "core/grammar/render/layout.js");
var Eval = require(cwd + "core/expr/code/eval.js");
var Lvalue = require(cwd + "core/expr/code/lvalue.js");
var Interpreter = require(cwd + "core/semantics/code/interpreter.js");
var Renderexp = require(cwd + "core/expr/code/renderexp.js");
var Enso = require(cwd + "enso.js");

var Stencil;

class StencilFrame extends Diagram.DiagramFrame {
  static new(...args) { return new StencilFrame(...args) };

  selection() { return this.selection$ };

  constructor(win, canvas, context, path = null) {
    super(win, canvas, context, "Model Editor");
    var self = this;
    self.actions$ = Enso.EMap.new();
    if (path) {
      self.set_path(path);
    }
  };

  set_stencil(val) { this.stencil$ = val };

  set_path(path) {
    var self = this, ext;
    ext = path.substr(path.lastIndexOf(".") + 1);
    if (ext.size_M() < 2) {
      self.raise("File has no extension");
    }
    self.path$ = path;
    return self.setup(ext, Load.load(self.path$));
  };

  setup(extension, data) {
    var self = this, rel, pos, position_map, size_V;
    self.extension$ = extension;
    self.stencil$ = Load.load(Enso.S(self.extension$, ".stencil"));
    if (! (self.stencil$.title() == null)) {
      self.win$.document().title = self.stencil$.title();
    }
    self.data$ = data;
    self.data$.finalize();
    self.build_diagram();
    if (data.factory().file_path().get$(0)) {
      rel = Enso.S(data.factory().file_path().get$(0), "-positions");
      pos = Enso.File.absolute_path(rel);
      if (Enso.File.exists_P(pos)) {
        position_map = Enso.System.readJSON(pos);
        self.set_positions(position_map);
        if (! (position_map.get$("*WINDOW*") == null)) {
          size_V = position_map.get$("*WINDOW*");
        }
      }
    }
    return self.clear_refresh();
  };

  set_positions(position_map) {
    var self = this, pnt, at1, at2, pos;
    return self.graphShapes$.each(function(tag, shape) {
      pnt = position_map.get$(tag);
      if (pnt) {
        if (Enso.System.test_type(shape, "Connector")) {
          at1 = shape.ends().get$(0).attach();
          at2 = shape.ends().get$(1).attach();
          at1.set_x(pnt.get$(0).x);
          at1.set_y(pnt.get$(0).y);
          at2.set_x(pnt.get$(1).x);
          return at2.set_y(pnt.get$(1).y);
        } else {
          pos = self.positions$.get$(shape.identity());
          if (pos) {
            pos.x().set_value(pnt.x);
            return pos.y().set_value(pnt.y);
          }
        }
      }
    });
  };

  build_diagram() {
    var self = this, white, black, env;
    white = self.factory$.Color(255, 255, 255);
    black = self.factory$.Color(0, 0, 0);
    env = Enso.EMap.new({font: self.factory$.Font(null, null, null, 14, "sans-serif"), pen: self.factory$.Pen(1, "solid", black), brush: self.factory$.Brush(black), nil: null});
    env .set$(self.stencil$.root(), self.data$);
    self.shapeToAddress$ = Enso.EMap.new();
    self.shapeToModel$ = Enso.EMap.new();
    self.tagModelToShape$ = Enso.EMap.new();
    self.graphShapes$ = Enso.EMap.new();
    self.stencil$.finalize();
    return self.construct(self.stencil$.body(), env, null, null, function(x, subid) {
      return self.set_root(x);
    });
  };

  do_open(file) {
    var self = this, parts;
    parts = file.split_M("/");
    return self.set_path(parts.get$(parts.size_M() - 1));
  };

  do_save() {
    var self = this, grammar, pos;
    grammar = Load.load(Enso.S(self.extension$, ".grammar"));
    pos = self.data$.factory().file_path().get$(0);
    Enso.File.write(function(output) {
      return Layout.DisplayFormat.print(grammar, self.data$, output, false);
    }, Enso.S(pos, "-NEW"));
    return Enso.System.writeJSON(Enso.S(pos, "-positions"), self.capture_positions());
  };

  capture_positions() {
    var self = this, position_map, at1, at2, h1, h2, pos, hash;
    position_map = Enso.System.JSHASH();
    position_map .set$("*VERSION*", 2);
    self.graphShapes$.each(function(tag, shape) {
      if (Enso.System.test_type(shape, "Connector")) {
        at1 = shape.ends().get$(0).attach();
        at2 = shape.ends().get$(1).attach();
        h1 = Enso.System.JSHASH();
        h2 = Enso.System.JSHASH();
        h1.x = at1.x();
        h1.y = at1.y();
        h2.x = at2.x();
        h2.y = at2.y();
        return position_map .set$(tag, [h1, h2]);
      } else {
        pos = self.position_fixed(shape);
        hash = Enso.System.JSHASH();
        hash.x = pos.x();
        hash.y = pos.y();
        return position_map .set$(tag, hash);
      }
    });
    return position_map;
  };

  on_double_click() {
    var self = this, pnt, text, address;
    return function(e) {
      pnt = self.getCursorPosition(e);
      text = self.find_in_ui(function(v) {
        return v.schema_class().name() == "Text";
      }, pnt);
      if (text) {
        address = self.shapeToAddress$.get$(text);
        if (address) {
          return self.edit_address(address, text);
        }
      }
    };
  };

  edit_address(address, shape) {
    var self = this, actions, name, action;
    if (Enso.System.test_type(address.type(), "Primitive")) {
      return self.selection$ = TextEditSelection.new(self, shape, address);
    } else {
      actions = Enso.System.JSHASH();
      self.find_all_objects(function(obj) {
        name = ObjectKey(obj);
        action = function(e) {
          address.set_value(obj);
          return shape.set_string(name);
        };
        actions .set$(name, action);
        return false;
      }, self.data$, address.index().type());
      if (actions != Enso.System.JSHASH()) {
        return Enso.System.popupMenu(actions);
      }
    }
  };

  on_right_down(pnt) {
    var self = this, actions;
    actions = [];
    self.find_in_ui(function(part, container) {
      if (self.actions$.get$(part.identity())) {
        actions.push(self.actions$.get$(part.identity()));
      }
      return false;
    }, pnt);
    return Enso.System.popupMenu(actions);
  };

  on_export() {
    var self = this, grammar;
    grammar = Load.load("diagram.grammar");
    return Enso.File.write(function(output) {
      return Layout.DisplayFormat.print(grammar, self.root$, output, false);
    }, Enso.S(self.path$, "-diagram"));
  };

  add_action(block, shape, name) {
    var self = this;
    if (! self.actions$.get$(shape.identity())) {
      self.actions$ .set$(shape.identity(), Enso.System.JSHASH());
    }
    return self.actions$.get$(shape.identity()) .set$(name, block);
  };

  construct(stencil, env, container, id, proc) {
    var self = this;
    return self.send(Enso.S("construct", stencil.schema_class().name()), stencil, env, container, id, proc);
  };

  make_styles(stencil, shape, env) {
    var self = this, font, pen, brush, newEnv, val;
    font = null;
    pen = null;
    brush = null;
    newEnv = env.clone();
    stencil.props().each(function(prop) {
      val = self.eval_M(prop.exp(), newEnv);
      switch (Renderexp.render(prop.loc())) {
        case "font.size":
          if (! font) {
            newEnv .set$("font", font = env.get$("font")._clone());
          }
          return font.set_points(val);
        case "font.weight":
          if (! font) {
            newEnv .set$("font", font = env.get$("font")._clone());
          }
          return font.set_weight(val);
        case "font.style":
          if (! font) {
            newEnv .set$("font", font = env.get$("font")._clone());
          }
          return font.set_style(val);
        case "font.variant":
          if (! font) {
            newEnv .set$("font", font = env.get$("font")._clone());
          }
          return font.set_variant(val);
        case "font.family":
          if (! font) {
            newEnv .set$("font", font = env.get$("font")._clone());
          }
          return font.set_family(val);
        case "font.color":
          if (! font) {
            newEnv .set$("font", font = env.get$("font")._clone());
          }
          return font.set_color(val);
        case "line.width":
          if (! pen) {
            newEnv .set$("pen", pen = env.get$("pen")._clone());
          }
          return pen.set_width(val);
        case "line.color":
          if (! pen) {
            newEnv .set$("pen", pen = env.get$("pen")._clone());
          }
          return pen.set_color(val);
        case "fill.color":
          if (! brush) {
            newEnv .set$("brush", brush = env.get$("brush")._clone());
          }
          return brush.set_color(val);
      }
    });
    if (font) {
      shape.styles().push(font);
    }
    if (pen) {
      shape.styles().push(pen);
    }
    if (brush) {
      return shape.styles().push(brush);
    }
  };

  constructAlt(obj, env, container, id, proc) {
    var self = this;
    return obj.alts().find_first(function(alt) {
      return self.construct(alt, env, container, id, proc);
    });
  };

  constructEAssign(obj, env, container, id, proc) {
    var self = this, nenv;
    nenv = env.clone();
    self.lvalue(obj.variable(), nenv).set_value(self.eval_M(obj.val(), nenv));
    return self.construct(obj.body(), nenv, container, id, proc);
  };

  constructGrid(grid, env, container, id, proc) {
    var self = this, columns, ncols, rows, nrows, body, dgrid;
    columns = [];
    ncols = 0;
    rows = [];
    nrows = 0;
    body = [];
    dgrid = self.factory$.Grid();
    return grid.axes().each(function(axis) {
      switch (axis.direction()) {
        case "columns":
          columns.push([]);
          self.construct(function(item, ni) {
            return columns.get$(ncols).push(item);
          }, axis.source(), env, dgrid, self.i());
          return ncols = ncols + 1;
        case "rows":
          rows.push([]);
          self.construct(function(item, ni) {
            return rows.get$(nrows).push(item);
          }, axis.source(), env, dgrid, self.i());
          return nrows = nrows + 1;
        case "body":
      }
    });
  };

  constructEFor(efor, env, container, id, proc) {
    var self = this, source, address, is_traversal, lhs, f, nenv, loc_name, newId, action, shape, factory, obj;
    source = self.eval_M(efor.list(), env);
    address = self.lvalue(efor.list(), env);
    is_traversal = false;
    if (Enso.System.test_type(efor.list(), "EField")) {
      lhs = self.eval_M(efor.list().e(), env);
      f = lhs.schema_class().all_fields().get$(efor.list().fname());
      if (! f) {
        self.raise(Enso.S("MISSING ", efor.list().fname(), " on ", lhs.schema_class()));
      }
      is_traversal = f.traversal();
    }
    nenv = env.clone();
    source.each_with_index(function(v, i) {
      nenv .set$(efor.var(), v);
      if (efor.index()) {
        nenv .set$(efor.index(), i);
      }
      if (v.schema_class().key()) {
        loc_name = v.get$(v.schema_class().key().name());
        if (id) {
          newId = Enso.S(id, ".", loc_name);
        } else {
          newId = loc_name;
        }
      } else {
        newId = id;
      }
      return self.construct(efor.body(), nenv, container, newId, function(shape, subid) {
        if (efor.label()) {
          action = is_traversal
            ? "Delete"
            : "Remove";
          self.add_action(function() {
            if (is_traversal) {
              return v.delete_in_place();
            } else {
              return self.addr().set_value(null);
            }
          }, container, Enso.S(action, " ", efor.label()));
        }
        return proc(shape, subid, v);
      });
    });
    if (efor.label()) {
      action = is_traversal
        ? "Create"
        : "Add";
      shape = container;
      return self.add_action(function() {
        factory = self.data$.factory();
        obj = factory.get$(address.type().name());
        return obj.schema_class().fields().each(function(field) {
          if ((field.key() && Enso.System.test_type(field.type(), "Primitive")) && field.type().name() == "str") {
            obj .set$(field.name(), Enso.S("<", field.name(), ">"));
          } else if ((! field.optional() && ! Enso.System.test_type(field.type(), "Primitive")) && ! (field.inverse() && field.inverse().traversal())) {
            obj .set$(field.name(), self.find_default_object(self.data$, field.type()));
          }
          return address.value().push(obj);
        });
      }, shape, Enso.S(action, " ", efor.label()));
    }
  };

  find_default_object(scan, type) {
    var self = this;
    return self.find_all_objects(function(x) {
      return scan;
    }, scan, type);
  };

  find_all_objects(block, scan, type) {
    var self = this;
    if (scan) {
      if (Schema.subclass_P(scan.schema_class(), type)) {
        if (block(scan)) {
          return scan;
        } else {
          return scan.schema_class().fields().each(function(field) {
            if (field.traversal()) {
              if (field.many()) {
                return scan.get$(field.name()).find_first(function(x) {
                  return self.find_all_objects(block, x, type);
                });
              } else {
                return self.find_all_objects(block, scan.get$(field.name()), type);
              }
            }
          });
        }
      }
    }
  };

  constructEIf(obj, env, container, id, proc) {
    var self = this, test;
    test = self.eval_M(obj.cond(), env);
    if (test) {
      return self.construct(obj.body(), env, container, id, proc);
    } else if (! (obj.body2() == null)) {
      return self.construct(obj.body2(), env, container, id, proc);
    }
  };

  constructEBlock(obj, env, container, id, proc) {
    var self = this;
    return obj.body().each(function(command) {
      return self.construct(command, env, container, id, proc);
    });
  };

  constructLabel(obj, env, container, id, proc) {
    var self = this, tag;
    return self.construct(obj.body(), env, container, id, function(shape, subid) {
      tag = self.evallabel(obj.label(), env);
      self.tagModelToShape$ .set$(tag._path(), shape);
      return proc(shape, subid);
    });
  };

  evallabel(label, env) {
    var self = this, obj;
    return obj = self.eval_M(label, env);
  };

  constructContainer(obj, env, container, id, proc) {
    var self = this, group;
    if (obj.direction() == 4) {
      return obj.items().each(function(item) {
        return self.construct(item, env, container, id, proc);
      });
    } else {
      group = self.factory$.Container();
      group.set_direction(obj.direction());
      obj.items().each(function(item) {
        return self.construct(item, env, group, id, function(x, subid) {
          group.items().push(x);
          if (obj.direction() == 3 || obj.direction() == 5) {
            return self.graphShapes$ .set$(subid, x);
          }
        });
      });
      self.make_styles(obj, group, env);
      if (proc) {
        return proc(group, id);
      }
    }
  };

  constructPage(obj, env, container, id, proc) {
    var self = this, page;
    self.make_styles(obj, self.group(), env);
    page = self.factory$.Page();
    page.set_name(self.eval_M(obj.namem(), env));
    self.construct(obj.part(), env, container, id, function(sub) {
      if (obj.content()) {
        self.raise(Enso.S("two content items in a page ", obj.content().to_s()));
      }
      return obj.set_content(sub);
    });
    if (proc) {
      return proc(page, id);
    }
  };

  constructText(obj, env, container, id, proc) {
    var self = this, val, addr, text;
    val = self.eval_M(obj.string(), env);
    addr = self.lvalue(obj.string(), env);
    text = self.factory$.Text();
    text.set_string(val.to_s());
    text.set_editable(obj.editable());
    self.make_styles(obj, text, env);
    if (addr) {
      self.shapeToAddress$ .set$(text, addr);
    }
    return proc(text, id);
  };

  constructShape(obj, env, container, id, proc) {
    var self = this, shape;
    shape = self.factory$.Shape();
    shape.set_kind(obj.kind());
    self.construct(obj.content(), env, shape, null, function(x, subid) {
      if (shape.content()) {
        self.error("Shape can only have one element");
      }
      return shape.set_content(x);
    });
    self.make_styles(obj, shape, env);
    return proc(shape, id);
  };

  makeLabel(exp, env) {
    var self = this, labelStr, label;
    labelStr = self.eval_M(exp, env);
    if (labelStr) {
      label = self.factory$.Text();
      label.set_string(labelStr);
      label.set_editable(false);
      return label;
    }
  };

  constructConnector(obj, env, container, id, proc) {
    var self = this, conn, ptemp, i, info, label, cend, x;
    conn = self.factory$.Connector();
    if (obj.ends().get$(0).label() == obj.ends().get$(1).label()) {
      ptemp = [self.factory$.EdgePos(1, 0.5), self.factory$.EdgePos(1, 0.75)];
    } else {
      ptemp = [self.factory$.EdgePos(0.5, 1), self.factory$.EdgePos(0.5, 0)];
    }
    i = 0;
    info = null;
    label = null;
    cend = null;
    obj.ends().each(function(e) {
      label = e.label() == null
        ? null
        : self.makeLabel(e.label(), env);
      cend = self.factory$.ConnectorEnd(e.arrow(), label);
      info = self.evallabel(e.part(), env);
      x = self.tagModelToShape$.get$(info._path());
      if (x == null) {
        self.fail(Enso.S("Shape ", info._path(), " does not exist in ", self.tagModelToShape$));
      }
      cend.set_to(x);
      cend.set_attach(ptemp.get$(i));
      i = i + 1;
      return conn.ends().push(cend);
    });
    self.make_styles(obj, conn, env);
    return proc(conn, id);
  };

  lvalue(exp, env) {
    var self = this;
    return Lvalue.lvalue(exp, Enso.EMap.new({env: env}));
  };

  eval_M(obj, env) {
    var self = this, interp;
    interp = Stencil.EvalColorC.new(self);
    return interp.dynamic_bind(function() {
      return interp.eval_M(obj);
    }, Enso.EMap.new({env: env}));
  };
};

class EvalColorC extends Enso.mix(Enso.EnsoBaseClass, Eval.EvalExpr) {
  static new(...args) { return new EvalColorC(...args) };

  constructor(d) {
    super();
    var self = this;
    self.diagram$ = d;
  };

  eval_Color(this_V) {
    var self = this;
    return self.diagram$.factory().Color(self.eval_M(this_V.r()), self.eval_M(this_V.g()), self.eval_M(this_V.b()));
  };
};

class TextEditSelection extends Diagram.Selection {
  static new(...args) { return new TextEditSelection(...args) };

  constructor(diagram, shape, address) {
    var r, n, extraWidth;
    super(diagram, null, true);
    var self = this;
    self.address$ = address;
    self.edit_selection$ = shape;
    r = diagram.boundary_fixed(shape);
    n = 2;
    extraWidth = 5;
    diagram.input().style.left = (r.x() - 1) + "px";
    diagram.input().style.top = (r.y() - 2) + "px";
    diagram.input().style.width = ((r.w() + n) + extraWidth) + "px";
    diagram.input().style.height = (r.h() + n) + "px";
    diagram.input().value = shape.string();
    diagram.input().focus();
  };

  clear() {
    var self = this, new_text, pos;
    new_text = self.diagram$.input().value;
    self.address$.set_value(new_text);
    self.edit_selection$.set_string(new_text);
    self.diagram$.input().style.left = "-100px";
    self.diagram$.input().style.top = "-100px";
    pos = self.diagram$.boundary(self.edit_selection$);
    self.diagram$.constrainText(self.edit_selection$, pos.x(), pos.y(), pos.w(), pos.h());
    return null;
  };
};

Stencil = {
  StencilFrame: StencilFrame,
  EvalColorC: EvalColorC,
  TextEditSelection: TextEditSelection,
};
module.exports = Stencil ;
