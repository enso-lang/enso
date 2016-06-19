define([
  "core/system/load/load",
  "core/diagram/code/constraints",
  "core/schema/code/factory"
],
function(Load, Constraints, Factory) {
  var Diagram ;
  var DiagramFrame = MakeClass("DiagramFrame", null, [],
    function() {
    },
    function(super$) {
      this.initialize = function(win, canvas, context, title) {
        var self = this; 
        if (title === undefined) title = "Diagram";
        self.$.win = win;
        self.$.canvas = canvas;
        self.$.context = context;
        self.$.menu_id = 0;
        self.$.selection = null;
        self.$.mouse_down = false;
        self.$.DIST = 4;
        self.$.factory = Factory.new(Load.load("diagram.schema"));
        return self.$.select_color = self.$.factory.Color(0, 255, 0);
      };

      this.listener = function() { return this.$.listener };
      this.set_listener = function(val) { this.$.listener  = val };

      this.factory = function() { return this.$.factory };
      this.set_factory = function(val) { this.$.factory  = val };

      this.on_open = function() {
        var self = this; 
        var dialog, path, extension, content;
        dialog = FileDialog.new(self, "Choose a file", "", "", "Diagrams (*.diagram;)|*.diagram;");
        if (dialog.show_modal() == ID_OK) {
          path = dialog.get_path();
          extension = File.extname(path);
          if (extension != "diagram") {
            self.raise("File is not a diagram");
          }
          content = Load(dialog.get_path());
          return self.set_root(content);
        }
      };

      this.set_root = function(root) {
        var self = this; 
        self.$.canvas.onmousedown = self.on_mouse_down();
        self.$.canvas.onmousemove = self.on_move();
        self.$.canvas.onmouseup = self.on_mouse_up();
        root.finalize();
        self.$.root = root;
        return self.clear_refresh();
      };

      this.clear_refresh = function() {
        var self = this; 
        self.$.cs = Constraints.ConstraintSystem.new();
        self.$.positions = new EnsoHash ({ });
        return self.paint();
      };

      this.on_mouse_down = function() {
        var self = this; 
        var pnt, subselect, val, select;
        return Proc.new(function(e) {
          pnt = self.factory().Point(e.pageX, e.pageY);
          self.$.mouse_down = true;
          if (self.$.selection) {
            subselect = self.$.selection.on_mouse_down(e);
            if (subselect == "cancel") {
              self.$.selection = null;
            }
            if (subselect) {
              self.$.selection = subselect;
            }
          }
          select = self.find_in_ui(function(x) {
            val = (self.$.find_container && self.$.find_container.Container_P()) && self.$.find_container.direction() == 3;
            return val;
          }, pnt);
          return self.set_selection(select, pnt);
        });
      };

      this.on_mouse_up = function() {
        var self = this; 
        return Proc.new(function(e) {
          return self.$.mouse_down = false;
        });
      };

      this.on_move = function() {
        var self = this; 
        return Proc.new(function(e) {
          if (self.$.selection) {
            return self.$.selection.on_move(e, self.$.mouse_down);
          }
        });
      };

      this.on_key = function() {
        var self = this; 
        return Proc.new(function(e) {
        });
      };

      this.clear_selection = function() {
        var self = this; 
        if (self.$.selection) {
          return self.$.selection = self.$.selection.clear();
        }
      };

      this.set_selection = function(select, pnt) {
        var self = this; 
        self.clear_selection();
        if (select) {
          if (select.Connector_P()) {
            self.$.selection = ConnectorSelection.new(self, select);
          } else {
            self.$.selection = MoveShapeSelection.new(self, select, pnt);
          }
        }
        return self.clear_refresh();
      };

      this.find_in_ui = function(filter, pnt) {
        var self = this; 
        return self.find1(filter, self.$.root, pnt);
      };

      this.find1 = function(filter, part, pnt) {
        var self = this; 
        var b, old_container, out;
        if (part.Connector_P()) {
          return self.findConnector(filter, part, pnt);
        } else {
          b = self.boundary(part);
          if (! (b == null)) {
            try {
              if (self.rect_contains(b, pnt)) {
                old_container = self.$.find_container;
                self.$.find_container = part;
                out = null;
                if (part.Container_P()) {
                  out = part.items().find(function(sub) {
                    return self.find1(filter, sub, pnt);
                  });
                  if (! out && filter(part)) {
                    out = part;
                  }
                } else if (part.Shape_P()) {
                  if (part.content()) {
                    out = self.find1(filter, part.content(), pnt);
                  }
                }
                self.$.find_container = old_container;
                if (out) {
                  return out;
                } else if (filter(part)) {
                  return part;
                }
              }
            } catch (e) {
              return puts(e.message());
            }
          }
        }
      };

      this.findConnector = function(filter, part, pnt) {
        var self = this; 
        var obj, from;
        part.ends().each(function(e) {
          if (e.label()) {
            obj = self.find1(filter, e.label(), pnt);
            return obj = self.find1(filter, e.other_label(), pnt);
          }
        });
        from = null;
        return part.path().each(function(to) {
          if (! (from == null)) {
            if ((self.between(from.x(), pnt.x(), to.x()) && self.between(from.y(), pnt.y(), to.y())) && self.dist_line(pnt, from, to) <= self.$.DIST) {
            }
          }
          return from = to;
        });
      };

      this.do_constraints = function() {
        var self = this; 
        return self.constrain(self.$.root, self.$.cs.value(0), self.$.cs.value(0));
      };

      this.constrain = function(part, x, y) {
        var self = this; 
        var w, h;
        w = null;
        h = null;
        self.with_styles(function() {
          if (part.Connector_P()) {
            return self.constrainConnector(part);
          } else {
            w = self.$.cs.value(0);
            h = self.$.cs.value(0);
            self.send(("constrain" + part.schema_class().name()).to_sym(), part, x, y, w, h);
            return self.$.positions._set(part, EnsoRect.new(x, y, w, h));
          }
        }, part);
        if (! (w == null)) {
          return [w, h];
        }
      };

      this.constrainContainer = function(part, basex, basey, width, height) {
        var self = this; 
        var pos, otherpos, x, y, info, w, h;
        pos = self.$.cs.value(0);
        otherpos = self.$.cs.value(0);
        x = basex.add(0);
        y = basey.add(0);
        part.items().each_with_index(function(item, i) {
          info = self.constrain(item, x, y);
          if (! (info == null)) {
            w = info._get(0);
            h = info._get(1);
            switch (part.direction()) {
              case 1:
                pos = pos.add(h);
                y = basey.add(pos);
                return width.max(w);
              case 2:
                pos = pos.add(w);
                x = basex.add(pos);
                return height.max(h);
              case 3:
                pos = pos.add(w);
                otherpos = otherpos.add(h);
                x = basex.add(pos);
                y = basey.add(otherpos);
                width.max(x.add(w));
                return height.max(y.add(h));
            }
          }
        });
        switch (part.direction()) {
          case 1:
            return height.max(pos);
          case 2:
            return width.max(pos);
        }
      };

      this.constrainShape = function(part, x, y, width, height) {
        var self = this; 
        var a, b, margin, info, ow, oh, sq2;
        switch (part.kind()) {
          case "box":
            a = self.$.cs.var("box1", 0);
            b = self.$.cs.var("box2", 0);
            break;
          case "oval":
            a = self.$.cs.var("pos1", 0);
            b = self.$.cs.var("pos2", 0);
            break;
          case "rounded":
            a = self.$.cs.var("rnd1", 20);
            b = self.$.cs.var("rnd2", 20);
            break;
        }
        margin = self.$.context.lineWidth;
        a = a.add(margin);
        b = b.add(margin);
        info = self.constrain(part.content(), x.add(a), y.add(b));
        ow = info._get(0);
        oh = info._get(1);
        if (part.kind() == "oval") {
          sq2 = 2 * Math.sqrt(2.0);
          a.max(ow.div(sq2));
          b.max(oh.div(sq2));
          a.max(b);
        }
        width.max(ow.add(a.mul(2)));
        return height.max(oh.add(b.mul(2)));
      };

      this.constrainText = function(part, x, y, width, height) {
        var self = this; 
        var info;
        info = self.$.context.measureText(part.string());
        width.max(info.width);
        return height.max(15);
      };

      this.constrainConnector = function(part) {
        var self = this; 
        var to, x, y;
        return part.ends().each(function(ce) {
          to = self.$.positions._get(ce.to());
          x = to.x().add(to.w().mul(ce.attach().x()));
          y = to.y().add(to.h().mul(ce.attach().y()));
          self.$.positions._set(ce, EnsoPoint.new(x, y));
          return self.constrainConnectorEnd(ce, x, y);
        });
      };

      this.constrainConnectorEnd = function(e, x, y) {
        var self = this; 
        if (e.label()) {
          self.constrain(e.label(), x, y);
        }
        if (e.other_label()) {
          return self.constrain(e.other_label(), x, y);
        }
      };

      this.boundary = function(shape) {
        var self = this; 
        var r;
        r = self.$.positions._get(shape);
        if (! (r == null)) {
          return EnsoRect.new(r.x().value(), r.y().value(), r.w().value(), r.h().value());
        }
      };

      this.position = function(shape) {
        var self = this; 
        var p;
        p = self.$.positions._get(shape);
        if (! (p == null)) {
          return EnsoPoint.new(p.x().value(), p.y().value());
        }
      };

      this.set_position = function(shape, x, y) {
        var self = this; 
        self.$.positions._get(shape).x().set_value(x);
        return self.$.positions._get(shape).y().set_value(y);
      };

      this.between = function(a, b, c) {
        var self = this; 
        return a - self.$.DIST <= b && b <= c + self.$.DIST || c - self.$.DIST <= b && b <= a + self.$.DIST;
      };

      this.rect_contains = function(rect, pnt) {
        var self = this; 
        return ((rect.x() <= pnt.x() && pnt.x() <= rect.x() + rect.w()) && rect.y() <= pnt.y()) && pnt.y() <= rect.y() + rect.h();
      };

      this.dist_line = function(p0, p1, p2) {
        var self = this; 
        var num, den;
        num = (p2.x() - p1.x()) * (p1.y() - p0.y()) - (p1.x() - p0.x()) * (p2.y() - p1.y());
        den = Math.pow(p2.x() - p1.x(), 2) + Math.pow(p2.y() - p1.y(), 2);
        return num.abs() / Math.sqrt(den);
      };

      this.paint = function() {
        var self = this; 
        if (self.$.positions.size() == 0) {
          self.do_constraints();
        }
        return self.draw(self.$.root);
      };

      this.draw = function(part) {
        var self = this; 
        self.$.context.textBaseline = "top";
        return self.with_styles(function() {
          return self.send(("draw" + part.schema_class().name()).to_sym(), part);
        }, part);
      };

      this.drawContainer = function(part) {
        var self = this; 
        var r;
        if (part.direction() == 3) {
          r = self.boundary(part);
          self.$.context.strokeRect(r.x(), r.y(), r.w(), r.h());
        }
        return (part.items().size() - 1).downto(function(i) {
          return self.draw(part.items()._get(i));
        }, 0);
      };

      this.drawShape = function(shape) {
        var self = this; 
        var r, margin, m2, rx, ry, x, y, rotation, start, finish, anticlockwise;
        r = self.boundary(shape);
        margin = self.$.context.lineWidth;
        m2 = margin - margin % 2;
        switch (shape.kind()) {
          case "box":
            self.$.context.strokeRect(r.x() + margin / 2, r.y() + margin / 2, r.w() - m2, r.h() - m2);
            break;
          case "oval":
            (rx = r.w() / 2);
            (ry = r.h() / 2);
            (x = r.x() + rx);
            (y = r.y() + ry);
            (rotation = 0);
            (start = 0);
            (finish = 2 * Math.PI);
            (anticlockwise = false);
            self.$.context.ellipse(x, y, rx, ry, rotation, start, finish, anticlockwise);
            self.$.context.stroke();
            break;
        }
        return self.draw(shape.content());
      };

      this.drawConnector = function(part) {
        var self = this; 
        var e0, e1, pFrom, pTo, sideFrom, sideTo, ps;
        e0 = part.ends()._get(0);
        e1 = part.ends()._get(1);
        pFrom = self.position(e0);
        pTo = self.position(e1);
        sideFrom = self.getSide(e0.attach());
        sideTo = self.getSide(e1.attach());
        if (sideFrom == sideTo) {
          ps = self.simpleSameSide(pFrom, pTo, sideFrom);
        } else if ((sideFrom - sideTo).abs() % 2 == 0) {
          ps = self.simpleOppositeSide(pFrom, pTo, sideFrom);
        } else {
          ps = self.simpleOrthogonalSide(pFrom, pTo, sideFrom);
        }
        ps.unshift(pFrom);
        ps.push(pTo);
        part.path().clear();
        ps.each(function(p) {
          return part.path().push(self.factory().Point(p.x(), p.y()));
        });
        self.$.context.beginPath();
        ps.map(function(p) {
          return self.$.context.lineTo(p.x(), p.y());
        });
        self.$.context.stroke();
        self.drawEnd(part.ends()._get(0));
        return self.drawEnd(part.ends()._get(1));
      };

      this.drawEnd = function(cend) {
        var self = this; 
        var side, r, angle, offset, lineHeight, size, index, pos, px, py, arrow;
        side = self.getSide(cend.attach());
        r = self.boundary(cend.label()) || self.boundary(cend.other_label());
        if (r) {
          switch (side) {
            case 0:
              angle = 90;
              offset = EnsoPoint.new(- r.h(), 0);
              break;
            case 1:
              angle = 0;
              offset = EnsoPoint.new(0, - r.h());
              break;
            case 2:
              angle = - 90;
              offset = EnsoPoint.new(r.h(), 0);
              break;
            case 3:
              angle = 0;
              r.set_y(r.y() - r.h());
              r.set_x(r.x() - r.w());
              offset = EnsoPoint.new(0, r.h());
              break;
          }
          lineHeight = 12;
          self.with_styles(function() {
            self.$.context.save();
            self.$.context.translate(r.x(), r.y());
            self.$.context.rotate((- Math.PI * angle) / 180);
            self.$.context.textAlign = "right";
            self.$.context.fillText(cend.label().string(), 0, lineHeight / 2);
            return self.$.context.restore();
          }, cend.label());
          self.with_styles(function() {
            self.$.context.save();
            self.$.context.translate(r.x() + offset.x(), r.y() + offset.y());
            self.$.context.rotate((- Math.PI * angle) / 180);
            self.$.context.textAlign = "right";
            self.$.context.fillText(cend.label().string(), 0, lineHeight / 2);
            return self.$.context.restore();
          }, cend.other_label());
        }
        if (cend.arrow() == ">" || cend.arrow() == "<") {
          size = 5;
          angle = (- Math.PI * (1 - side)) / 2;
          self.$.context.beginPath();
          index = 0;
          pos = self.position(cend);
          arrow = [EnsoPoint.new(0, 0), EnsoPoint.new(2, 1), EnsoPoint.new(2, - 1), EnsoPoint.new(0, 0)].each(function(p) {
            px = Math.cos(angle) * p.x() - Math.sin(angle) * p.y();
            py = Math.sin(angle) * p.x() + Math.cos(angle) * p.y();
            px = px * size + pos.x();
            py = py * size + pos.y();
            if (index == 0) {
              self.$.context.moveTo(px, py);
            } else {
              self.$.context.lineTo(px, py);
            }
            return index = index + 1;
          });
          self.$.context.closePath();
          return self.$.context.fill();
        }
      };

      this.simpleSameSide = function(a, b, d) {
        var self = this; 
        var z;
        switch (d) {
          case 2:
            z = [a.y() + 10, b.y() + 10].max();
            return [EnsoPoint.new(a.x(), z), EnsoPoint.new(b.x(), z)];
          case 0:
            z = [a.y() - 10, b.y() - 10].min();
            return [EnsoPoint.new(a.x(), z), EnsoPoint.new(b.x(), z)];
          case 1:
            z = [a.x() + 10, b.x() + 10].max();
            return [EnsoPoint.new(z, a.y()), EnsoPoint.new(z, b.y())];
          case 3:
            z = [a.x() - 10, b.x() - 10].min();
            return [EnsoPoint.new(z, a.y()), EnsoPoint.new(z, b.y())];
        }
      };

      this.simpleOppositeSide = function(a, b, d) {
        var self = this; 
        var z;
        switch (d) {
          case 0:
          case 2:
            z = self.average(a.y(), b.y());
            return [EnsoPoint.new(a.x(), z), EnsoPoint.new(b.x(), z)];
          case 1:
          case 3:
            z = self.average(a.x(), b.x());
            return [EnsoPoint.new(z, a.y()), EnsoPoint.new(z, b.y())];
        }
      };

      this.average = function(m, n) {
        var self = this; 
        return Integer((m + n) / 2);
      };

      this.simpleOrthogonalSide = function(a, b, d) {
        var self = this; 
        switch (d) {
          case 0:
          case 2:
            return [EnsoPoint.new(a.x(), b.y())];
          case 1:
          case 3:
            return [EnsoPoint.new(b.x(), a.y())];
        }
      };

      this.getSide = function(cend) {
        var self = this; 
        if (cend.y() == 0) {
          return 0;
        } else if (cend.x() == 1) {
          return 1;
        } else if (cend.y() == 1) {
          return 2;
        } else if (cend.x() == 0) {
          return 3;
        }
      };

      this.drawText = function(text) {
        var self = this; 
        var r;
        r = self.boundary(text);
        return self.$.context.fillText(text.string(), r.x(), r.y());
      };

      this.with_styles = function(block, part) {
        var self = this; 
        if (! (part == null)) {
          if (part.styles().size() > 0) {
            self.$.context.save();
            part.styles().each(function(style) {
              if (style.Pen_P()) {
                if (style.width()) {
                  self.$.context.lineWidth = style.width();
                }
                if (style.color()) {
                  return self.$.context.strokeStyle = self.makeColor(style.color());
                }
              } else if (style.Font_P()) {
                return self.$.context.font = self.makeFont(style);
              } else if (style.Brush_P()) {
                return self.$.context.fillStyle = self.makeColor(style.color());
              }
            });
            block();
            return self.$.context.restore();
          } else {
            return block();
          }
        }
      };

      this.makeColor = function(c) {
        var self = this; 
        return S("\\#", self.to_byte(c.r()), self.to_byte(c.g()), self.to_byte(c.b()));
      };

      this.to_byte = function(v) {
        var self = this; 
        return v.to_hex().rjust(2, "0");
      };

      this.makeFont = function(font) {
        var self = this; 
        var s;
        s = "";
        if (! (font.style() == null)) {
          s = (s + font.style()) + " ";
        }
        if (! (font.weight() == null)) {
          s = (s + font.weight()) + " ";
        }
        s = s + S(font.size(), "px");
        if (! (font.family() == null)) {
          s = (s + " ") + font.family();
        }
        return s;
      };
    });

  var MoveShapeSelection = MakeClass("MoveShapeSelection", null, [],
    function() {
    },
    function(super$) {
      this.initialize = function(diagram, part, down) {
        var self = this; 
        self.$.diagram = diagram;
        self.$.part = part;
        self.$.down = down;
        return self.$.move_base = self.$.diagram.boundary(part);
      };

      this.on_move = function() {
        var self = this; 
        return Proc.new(function(e, down) {
          if (down) {
            self.$.diagram.set_position(self.$.part, self.$.move_base.x() + e.x() - self.$.down.x(), self.$.move_base.y() + e.y() - self.$.down.y());
            return self.$.diagram.clear_refresh();
          }
        });
      };

      this.is_selected = function(check) {
        var self = this; 
        return self.$.part == check;
      };

      this.paint = function(dc) {
        var self = this; 
      };

      this.on_mouse_down = function(e) {
        var self = this; 
      };

      this.clear = function() {
        var self = this; 
      };
    });

  var ConnectorSelection = MakeClass("ConnectorSelection", null, [],
    function() {
    },
    function(super$) {
      this.initialize = function(diagram, conn) {
        var self = this; 
        self.$.diagram = diagram;
        return self.$.conn = conn;
      };

      this.is_selected = function(check) {
        var self = this; 
        return self.$.conn == check;
      };

      this.paint = function(dc) {
        var self = this; 
        var size;
        self.raise("SHOULD NOT BE HERE");
        dc.set_brush(self.factory().Brush(self.factory().Color(255, 0, 0)));
        dc.set_pen(NULL_PEN);
        return size = 8;
      };

      this.on_mouse_down = function(e) {
        var self = this; 
        var size, pnt, p, r;
        size = 8;
        pnt = self.factory().Point(e.x(), e.y());
        p = self.$.conn.path()._get(0);
        r = self.factory().Rect(p.x() - size / 2, p.y() - size / 2, size, size);
        if (self.rect_contains(r, pnt)) {
          return PointSelection.new(self.$.diagram, self.$.conn.ends()._get(0), self, p);
        } else {
          p = self.$.conn.path()._get(- 1);
          r = self.$.diagram.factory().Rect(p.x() - size / 2, p.y() - size / 2, size, size);
          if (self.rect_contains(r, pnt)) {
            return PointSelection.new(self.$.diagram, self.$.conn.ends()._get(1), self, p);
          }
        }
      };

      this.on_move = function(e, down) {
        var self = this; 
      };

      this.clear = function() {
        var self = this; 
      };
    });

  var PointSelection = MakeClass("PointSelection", null, [],
    function() {
    },
    function(super$) {
      this.initialize = function(diagram, ce, selection, pnt) {
        var self = this; 
        self.$.diagram = diagram;
        self.$.ce = ce;
        self.$.selection = selection;
        return self.$.pnt = pnt;
      };

      this.is_selected = function(check) {
        var self = this; 
        return self.$.ce == check;
      };

      this.paint = function(dc) {
        var self = this; 
        var size;
        dc.set_brush(self.$.diagram.factory().Brush(self.$.diagram.factory().Color(0, 0, 255)));
        dc.set_pen(NULL_PEN);
        size = 8;
        return dc.draw_rectangle(self.$.pnt.x() - size / 2, self.$.pnt.y() - size / 2, size, size);
      };

      this.on_mouse_down = function(e) {
        var self = this; 
      };

      this.on_move = function(e, down) {
        var self = this; 
        var pos, x, y, angle, nx, ny;
        if (down) {
          pos = self.$.diagram.boundary(self.$.ce.to());
          x = ((e.x() - pos.x()) + pos.w() / 2) / pos.w() / Float(2);
          y = ((e.y() - pos.y()) + pos.h() / 2) / pos.h() / Float(2);
          if (x == 0 && y == 0) {
            return null;
          } else {
            angle = Math.atan2(y, x);
            nx = self.normalize(Math.cos(angle));
            ny = self.normalize(Math.sin(angle));
            self.$.ce.attach().set_x(nx);
            self.$.ce.attach().set_y(ny);
            return self.$.diagram.clear_refresh();
          }
        }
      };

      this.normalize = function(n) {
        var self = this; 
        var n;
        n = n * Math.sqrt(2);
        n = [- 1, n].max();
        n = [1, n].min();
        n = (n + 1) / 2;
        return n;
      };

      this.clear = function() {
        var self = this; 
        return self.$.selection;
      };
    });

  var EnsoPoint = MakeClass("EnsoPoint", null, [],
    function() {
    },
    function(super$) {
      this.initialize = function(x, y) {
        var self = this; 
        self.$.x = x;
        return self.$.y = y;
      };

      this.x = function() { return this.$.x };
      this.set_x = function(val) { this.$.x  = val };

      this.y = function() { return this.$.y };
      this.set_y = function(val) { this.$.y  = val };
    });

  var EnsoRect = MakeClass("EnsoRect", null, [],
    function() {
    },
    function(super$) {
      this.initialize = function(x, y, w, h) {
        var self = this; 
        self.$.x = x;
        self.$.y = y;
        self.$.w = w;
        return self.$.h = h;
      };

      this.x = function() { return this.$.x };
      this.set_x = function(val) { this.$.x  = val };

      this.y = function() { return this.$.y };
      this.set_y = function(val) { this.$.y  = val };

      this.w = function() { return this.$.w };
      this.set_w = function(val) { this.$.w  = val };

      this.h = function() { return this.$.h };
      this.set_h = function(val) { this.$.h  = val };
    });

  Diagram = {
    DiagramFrame: DiagramFrame,
    MoveShapeSelection: MoveShapeSelection,
    ConnectorSelection: ConnectorSelection,
    PointSelection: PointSelection,
    EnsoPoint: EnsoPoint,
    EnsoRect: EnsoRect,

  };
  return Diagram;
})
