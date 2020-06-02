'use strict'

//// Diagram ////

var cwd = process.cwd() + '/';
var Load = require(cwd + "core/system/load/load.js");
var Constraints = require(cwd + "core/diagram/code/constraints.js");
var Factory = require(cwd + "core/schema/code/factory.js");
var Enso = require(cwd + "enso.js");

var Diagram;

class DiagramFrame extends Enso.EnsoBaseClass {
  static new(...args) { return new DiagramFrame(...args) };

  constructor(win, canvas, input, title = "Diagram") {
    var canvasWidth, canvasHeight;
    super();
    var self = this;
    self.win$ = win;
    self.canvas$ = canvas;
    self.input$ = input;
    self.context$ = self.canvas$.getContext("2d");
    self.menuidentity$ = 0;
    self.selection$ = null;
    self.mouse_down$ = false;
    self.DIST$ = 4;
    self.text_margin$ = 4;
    self.defaultConnectorDist$ = 20;
    self.cs$ = Constraints.ConstraintSystem.new();
    self.factory$ = Factory.SchemaFactory.new(Load.load("diagram.schema"));
    self.select_color$ = self.factory$.Color(0, 255, 0);
    self.win$.addEventListener("resize", self.resizeCanvas(), false);
    canvasWidth = self.win$.innerWidth;
    canvasHeight = self.win$.innerHeight;
    self.canvas$.width = canvasWidth;
    self.canvas$.height = canvasHeight;
  };

  factory() { return this.factory$ };
  set_factory(val) { this.factory$ = val };

  context() { return this.context$ };
  set_context(val) { this.context$ = val };

  input() { return this.input$ };
  set_input(val) { this.input$ = val };

  resizeCanvas() {
    var self = this, canvasWidth, canvasHeight, bounds;
    return function() {
      canvasWidth = self.win$.innerWidth;
      canvasHeight = self.win$.innerHeight;
      self.canvas$.width = canvasWidth;
      self.canvas$.height = canvasHeight;
      bounds = self.boundary(self.root$);
      if (bounds) {
        bounds.set_w(self.cs$.value(canvasWidth));
        bounds.set_h(self.cs$.value(canvasHeight));
        return self.clear_refresh();
      }
    };
  };

  set_root(root) {
    var self = this;
    self.context$.font = "13px sans-serif";
    self.context$.strokeStyle = "#000000";
    self.context$.textBaseline = "top";
    self.canvas$.onmousedown = self.on_mouse_down();
    self.canvas$.onmousemove = self.on_move();
    self.canvas$.onmouseup = self.on_mouse_up();
    self.canvas$.ondblclick = self.on_double_click();
    root.finalize();
    self.root$ = root;
    self.positions$ = Enso.EMap.new();
    self.do_constraints();
    return self.resizeCanvas();
  };

  getCursorPosition(event) {
    var self = this, rect, x, y;
    rect = self.canvas$.getBoundingClientRect();
    x = event.clientX - rect.left;
    y = event.clientY - rect.top;
    return self.factory$.Point(x, y);
  };

  on_mouse_down() {
    var self = this, pnt, done, clear, select;
    return function(e) {
      pnt = self.getCursorPosition(e);
      self.mouse_down$ = true;
      done = false;
      clear = self.selection$;
      if (e.ctrlKey) {
        self.on_right_down(pnt);
        done = true;
      } else if (self.selection$) {
        if (self.selection$.do_mouse_down(pnt)) {
          done = true;
        } else {
          self.selection$.clear();
          self.selection$ = null;
        }
      }
      if (! done) {
        select = self.find_in_ui(function(x, container) {
          return (container && Enso.System.test_type(container, "Container")) && container.direction() == 3;
        }, pnt);
        done = self.set_selected_part(select, pnt);
      }
      if (done || clear) {
        return self.clear_refresh();
      }
    };
  };

  on_mouse_up() {
    var self = this;
    return function(e) {
      self.mouse_down$ = false;
      if (self.selection$) {
        return self.selection$.do_mouse_up();
      }
    };
  };

  on_move() {
    var self = this, pnt;
    return function(e) {
      pnt = self.getCursorPosition(e);
      if (self.selection$) {
        return self.selection$.do_move(pnt, self.mouse_down$);
      }
    };
  };

  on_key() {
    var self = this;
    return function(e) {
    };
  };

  set_selected_part(select, pnt) {
    var self = this;
    if (select) {
      if (Enso.System.test_type(select, "Connector")) {
        self.selection$ = ConnectorSelection.new(self, select);
      } else {
        self.selection$ = MoveShapeSelection.new(self, select, EnsoPoint.new(pnt.x(), pnt.y()));
      }
      return true;
    }
  };

  find_in_ui(filter, pnt) {
    var self = this;
    return self.find1(filter, self.root$, null, pnt);
  };

  find1(filter, part, container, pnt) {
    var self = this, b, out;
    if (Enso.System.test_type(part, "Connector")) {
      return self.findConnector(filter, part, container, pnt);
    } else {
      b = self.boundary_fixed(part);
      if (b) {
        if (self.rect_contains(b, pnt)) {
          out = null;
          if (Enso.System.test_type(part, "Container")) {
            out = part.items().find_first(function(sub) {
              return self.find1(filter, sub, part, pnt);
            });
          } else if (Enso.System.test_type(part, "Shape")) {
            if (part.content()) {
              out = self.find1(filter, part.content(), part, pnt);
            }
          }
          if (! out && filter(part, container)) {
            out = part;
          }
          return out;
        }
      }
    }
  };

  findConnector(filter, part, container, pnt) {
    var self = this, obj, from;
    obj = part.ends().find_first(function(e) {
      if (e.label()) {
        obj = self.find1(filter, e.label(), container, pnt);
      }
      return obj;
    });
    if (obj == null) {
      from = null;
      part.path().each(function(to) {
        if (! (from == null)) {
          if ((self.between(from.x(), pnt.x(), to.x()) && self.between(from.y(), pnt.y(), to.y())) && self.dist_line(pnt, from, to) <= self.DIST$) {
            obj = part;
          }
        }
        return from = to;
      });
    }
    return obj;
  };

  getSide(cend) {
    var self = this;
    if (cend.y() == 0) {
      return 0;
    } else if (cend.x() == 1) {
      return 1;
    } else if (cend.y() == 1) {
      return 2;
    } else if (cend.x() == 0) {
      return 3;
    } else {
      return puts("NO SIDE!!!!");
    }
  };

  do_constraints() {
    var self = this;
    return self.constrain(self.root$, self.cs$.value(0), self.cs$.value(0));
  };

  constrain(part, x, y) {
    var self = this, w, h;
    w = null;
    h = null;
    self.with_styles(function() {
      if (Enso.System.test_type(part, "Connector")) {
        return self.constrainConnector(part);
      } else {
        w = self.cs$.value(0);
        h = self.cs$.value(0);
        self.send(("constrain" + part.schema_class().name()).to_sym(), part, x, y, w, h);
        return self.positions$.set(part.identity(), EnsoRect.new(x, y, w, h));
      }
    }, part);
    if (! (w == null)) {
      return [w, h];
    }
  };

  constrainGrid(part, basex, basey, width, height) {
    var self = this;
  };

  constrainContainer(part, basex, basey, width, height) {
    var self = this, pos, otherpos, x, y, info, w, h;
    pos = self.cs$.value(0);
    otherpos = self.cs$.value(0);
    x = basex.add(0);
    y = basey.add(0);
    part.items().each_with_index(function(item, i) {
      info = self.constrain(item, x, y);
      if (! (info == null)) {
        w = info.get$(0);
        h = info.get$(1);
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
            pos = pos.add(w).add(10);
            otherpos = otherpos.add(h).add(10);
            x = basex.add(pos);
            y = basey.add(otherpos);
            width.max(x.add(w));
            return height.max(y.add(h));
          case 5:
            x = basex.add(0);
            y = basey.add(0);
            width.max(w);
            return height.max(h);
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

  constrainShape(part, x, y, width, height) {
    var self = this, a, b, margin, info, ow, oh, sq2;
    switch (part.kind()) {
      case "box":
        a = self.cs$.variable("box1", 0);
        b = self.cs$.variable("box2", 0);
        break;
      case "oval":
        a = self.cs$.variable("pos1", 0);
        b = self.cs$.variable("pos2", 0);
        break;
      case "rounded":
        a = self.cs$.variable("rnd1", 20);
        b = self.cs$.variable("rnd2", 20);
        break;
    }
    margin = self.context$.lineWidth * 6;
    a = a.add(margin);
    b = b.add(margin);
    info = self.constrain(part.content(), x.add(a), y.add(b));
    ow = info.get$(0);
    oh = info.get$(1);
    if (part.kind() == "oval") {
      sq2 = 2 * Math.sqrt(2.0);
      a.max(ow.div(sq2));
      b.max(oh.div(sq2));
      a.max(b);
    }
    width.max(ow.add(a.mul(2)));
    return height.max(oh.add(b.mul(2)));
  };

  constrainText(part, x, y, width, height) {
    var self = this, info;
    info = self.context$.measureText(part.string());
    width.max(info.width + self.text_margin$);
    return height.max(15);
  };

  constrainConnector(part) {
    var self = this, to, dynamic, x, y;
    return part.ends().each(function(ce) {
      to = self.boundary(ce.to());
      dynamic = ce.attach().dynamic_update();
      x = to.x().add(to.w().mul(dynamic.x()));
      y = to.y().add(to.h().mul(dynamic.y()));
      self.positions$.set(ce.identity(), EnsoPoint.new(x, y));
      return self.constrainConnectorEnd(ce, x, y);
    });
  };

  constrainConnectorEnd(e, x, y) {
    var self = this;
    if (e.label()) {
      return self.constrain(e.label(), x, y);
    }
  };

  boundary(shape) {
    var self = this;
    return self.positions$.get$(shape.identity());
  };

  boundary_fixed(shape) {
    var self = this, r;
    r = self.boundary(shape);
    if (! (r == null)) {
      return EnsoRect.new(r.x().value(), r.y().value(), r.w().value(), r.h().value());
    }
  };

  position(shape) {
    var self = this;
    return self.positions$.get$(shape.identity());
  };

  position_fixed(shape) {
    var self = this, p;
    p = self.position(shape);
    if (! (p == null)) {
      return EnsoPoint.new(p.x().value(), p.y().value());
    }
  };

  set_position(shape, x, y) {
    var self = this, r;
    r = self.boundary(shape);
    r.x().set_value(x);
    return r.y().set_value(y);
  };

  between(a, b, c) {
    var self = this;
    return a - self.DIST$ <= b && b <= c + self.DIST$ || c - self.DIST$ <= b && b <= a + self.DIST$;
  };

  rect_contains(rect, pnt) {
    var self = this;
    return ((rect.x() <= pnt.x() && pnt.x() <= rect.x() + rect.w()) && rect.y() <= pnt.y()) && pnt.y() <= rect.y() + rect.h();
  };

  dist_line(p0, p1, p2) {
    var self = this, num, den;
    num = (p2.x() - p1.x()) * (p1.y() - p0.y()) - (p1.x() - p0.x()) * (p2.y() - p1.y());
    den = Math.pow(p2.x() - p1.x(), 2) + Math.pow(p2.y() - p1.y(), 2);
    return num.abs() / Math.sqrt(den);
  };

  clear_refresh() {
    var self = this;
    self.context$.fillStyle = "white";
    self.context$.fillRect(0, 0, 5000, 5000);
    self.context$.fillStyle = "black";
    self.draw(self.root$, 0);
    if (self.selection$) {
      return self.selection$.do_paint();
    }
  };

  draw(part, n) {
    var self = this;
    self.context$.font = "13px sans-serif";
    self.context$.strokeStyle = "#000000";
    self.context$.textBaseline = "top";
    return self.with_styles(function() {
      return self.send(("draw" + part.schema_class().name()).to_sym(), part, n + 1);
    }, part);
  };

  drawContainer(part, n) {
    var self = this, current, len, start;
    if (part.direction() == 5) {
      current = part.curent() == null
        ? 0
        : part.current();
      return self.draw(part.items().get$(current), n + 1);
    } else {
      len = part.items().size_M() - 1;
      start = 0;
      return start.upto(function(i) {
        return self.draw(part.items().get$(i), n + 1);
      }, len);
    }
  };

  drawPage(shape, n) {
    var self = this, r;
    r = self.boundary_fixed(shape);
    self.context$.save();
    self.context$.beginPath();
    self.context$.fillStyle = "black";
    self.context$.fillText(shape.name(), r.x() + 2, r.y(), 1000);
    self.context$.fill();
    self.context$.restore();
    return self.draw(shape.content(), n + 1);
  };

  drawGrid(grid, n) {
    var self = this;
  };

  drawShape(shape, n) {
    var self = this, r, margin, m2, rx, ry, x, y, rotation, start, finish, anticlockwise;
    r = self.boundary_fixed(shape);
    if (r) {
      margin = self.context$.lineWidth * 6;
      m2 = margin - margin % 2;
      switch (shape.kind()) {
        case "box":
          self.context$.save();
          self.context$.rect(r.x() + margin / 2, r.y() + margin / 2, r.w() - m2, r.h() - m2);
          self.context$.fillStyle = "Cornsilk";
          self.context$.shadowColor = "#999";
          self.context$.shadowBlur = 6;
          self.context$.shadowOffsetX = 2;
          self.context$.shadowOffsetY = 2;
          self.context$.fill();
          self.context$.stroke();
          self.context$.restore();
          break;
        case "oval":
          rx = r.w() / 2;
          ry = r.h() / 2;
          x = r.x() + rx;
          y = r.y() + ry;
          rotation = 0;
          start = 0;
          finish = 2 * Math.PI;
          anticlockwise = false;
          self.context$.save();
          self.context$.fillStyle = "Cornsilk";
          self.context$.shadowColor = "#999";
          self.context$.shadowBlur = 6;
          self.context$.shadowOffsetX = 2;
          self.context$.shadowOffsetY = 2;
          self.context$.beginPath();
          self.context$.ellipse(x, y, rx, ry, rotation, start, finish, anticlockwise);
          self.context$.fill();
          self.context$.restore();
          break;
      }
    }
    return self.draw(shape.content(), n + 1);
  };

  drawConnector(part, n) {
    var self = this, e0, e1, rFrom, rTo, pFrom, thetaFrom, pTo, thetaTo, sideFrom, sideTo, ps;
    e0 = part.ends().get$(0);
    e1 = part.ends().get$(1);
    rFrom = self.boundary_fixed(e0.to());
    rTo = self.boundary_fixed(e1.to());
    switch (e0.to().kind()) {
      case "box":
      case "rounded":
        pFrom = EnsoPoint.new(rFrom.x() + rFrom.w() * e0.attach().x(), rFrom.y() + rFrom.h() * e0.attach().y());
        break;
      case "oval":
        thetaFrom = - Math.atan2(e0.attach().y() - 0.5, e0.attach().x() - 0.5);
        pFrom = EnsoPoint.new(rFrom.x() + rFrom.w() * (0.5 + Math.cos(thetaFrom) / 2), rFrom.y() + rFrom.h() * (0.5 - Math.sin(thetaFrom) / 2));
        break;
    }
    switch (e1.to().kind()) {
      case "box":
      case "rounded":
        pTo = EnsoPoint.new(rTo.x() + rTo.w() * e1.attach().x(), rTo.y() + rTo.h() * e1.attach().y());
        break;
      case "oval":
        thetaTo = - Math.atan2(e1.attach().y() - 0.5, e1.attach().x() - 0.5);
        pTo = EnsoPoint.new(rTo.x() + rTo.w() * (0.5 + Math.cos(thetaTo) / 2), rTo.y() + rTo.h() * (0.5 - Math.sin(thetaTo) / 2));
        break;
    }
    sideFrom = self.getSide(e0.attach());
    sideTo = self.getSide(e1.attach());
    if (sideFrom == sideTo) {
      ps = self.simpleSameSide(pFrom, pTo, sideFrom);
    } else if ((sideFrom - sideTo).abs() % 2 == 0) {
      ps = self.simpleOppositeSide(pFrom, pTo, sideFrom);
    } else if (e0.to() == e1.to()) {
      ps = self.sameObjectCorner(pFrom, pTo, sideFrom);
    } else {
      ps = self.simpleOrthogonalSide(pFrom, pTo, sideFrom);
    }
    ps.unshift(pFrom);
    ps.push(pTo);
    part.path().clear();
    ps.each(function(p) {
      return part.path().push(self.factory$.Point(p.x(), p.y()));
    });
    self.context$.save();
    self.context$.beginPath();
    ps.map(function(p) {
      return self.context$.lineTo(p.x(), p.y());
    });
    self.context$.stroke();
    self.drawEnd(e0, e1, pFrom, pTo);
    self.drawEnd(e1, e0, pTo, pFrom);
    return self.context$.restore();
  };

  drawEnd(cend, other_end, r, s) {
    var self = this, side, rFrom, rTo, angle, align, offsetX, offsetY, textHeight, size_V, index, px, py, arrow;
    side = self.getSide(cend.attach());
    rFrom = self.boundary_fixed(cend.to());
    rTo = self.boundary_fixed(other_end.to());
    switch (side) {
      case 0:
        angle = 90;
        align = "left";
        offsetX = 1;
        if (s.x() < r.x()) {
          offsetY = 0;
        } else {
          offsetY = - 1;
        }
        break;
      case 1:
        angle = 0;
        align = "left";
        offsetX = 1;
        if (s.y() < r.y()) {
          offsetY = 0;
        } else {
          offsetY = - 1;
        }
        break;
      case 2:
        angle = - 90;
        align = "left";
        offsetX = 1;
        if (r.x() < s.x()) {
          offsetY = 0;
        } else {
          offsetY = - 1;
        }
        break;
      case 3:
        angle = 0;
        align = "right";
        offsetX = - 1;
        if (s.y() < r.y()) {
          offsetY = 0;
        } else {
          offsetY = - 1;
        }
        break;
    }
    self.with_styles(function() {
      self.context$.save();
      self.context$.translate(r.x(), r.y());
      self.context$.rotate((- Math.PI * angle) / 180);
      self.context$.textAlign = align;
      textHeight = 16;
      self.context$.fillText(cend.label().string(), offsetX * 3, offsetY * textHeight);
      return self.context$.restore();
    }, cend.label());
    if (cend.arrow() == ">" || cend.arrow() == "<") {
      self.context$.save();
      size_V = 5;
      angle = (- Math.PI * (1 - side)) / 2;
      self.context$.beginPath();
      index = 0;
      rFrom = self.boundary_fixed(cend.to());
      arrow = [EnsoPoint.new(0, 0), EnsoPoint.new(2, 1), EnsoPoint.new(2, - 1), EnsoPoint.new(0, 0)].each(function(p) {
        px = Math.cos(angle) * p.x() - Math.sin(angle) * p.y();
        py = Math.sin(angle) * p.x() + Math.cos(angle) * p.y();
        px = px * size_V + r.x();
        py = py * size_V + r.y();
        if (index == 0) {
          self.context$.moveTo(px, py);
        } else {
          self.context$.lineTo(px, py);
        }
        return index = index + 1;
      });
      self.context$.closePath();
      self.context$.fill();
      return self.context$.restore();
    }
  };

  simpleSameSide(a, b, d) {
    var self = this, z;
    switch (d) {
      case 0:
        z = Enso.System.min(a.y() - self.defaultConnectorDist$, b.y() - self.defaultConnectorDist$);
        return [EnsoPoint.new(a.x(), z), EnsoPoint.new(b.x(), z)];
      case 1:
        z = Enso.System.max(a.x() + self.defaultConnectorDist$, b.x() + self.defaultConnectorDist$);
        return [EnsoPoint.new(z, a.y()), EnsoPoint.new(z, b.y())];
      case 2:
        z = Enso.System.max(a.y() + self.defaultConnectorDist$, b.y() + self.defaultConnectorDist$);
        return [EnsoPoint.new(a.x(), z), EnsoPoint.new(b.x(), z)];
      case 3:
        z = Enso.System.min(a.x() - self.defaultConnectorDist$, b.x() - self.defaultConnectorDist$);
        return [EnsoPoint.new(z, a.y()), EnsoPoint.new(z, b.y())];
    }
  };

  simpleOppositeSide(a, b, d) {
    var self = this, z;
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

  average(m, n) {
    var self = this;
    return Enso.Integer((m + n) / 2);
  };

  sameObjectCorner(a, b, d) {
    var self = this, z, m;
    switch (d) {
      case 0:
      case 2:
        if (d == 0) {
          z = a.y() - self.defaultConnectorDist$;
        } else {
          z = a.y() + self.defaultConnectorDist$;
        }
        if (a.x() > b.x()) {
          m = b.x() - self.defaultConnectorDist$;
        } else {
          m = b.x() + self.defaultConnectorDist$;
        }
        return [EnsoPoint.new(a.x(), z), EnsoPoint.new(m, z), EnsoPoint.new(m, b.y())];
      case 1:
      case 3:
        if (d == 1) {
          z = a.x() - self.defaultConnectorDist$;
        } else {
          z = a.x() + self.defaultConnectorDist$;
        }
        if (a.y() > b.y()) {
          m = b.y() - self.defaultConnectorDist$;
        } else {
          m = b.y() + self.defaultConnectorDist$;
        }
        return [EnsoPoint.new(z, a.y()), EnsoPoint.new(z, m), EnsoPoint.new(b.x(), m)];
    }
  };

  simpleOrthogonalSide(a, b, d) {
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

  drawText(text, n) {
    var self = this, r;
    r = self.boundary_fixed(text);
    self.context$.save();
    self.context$.beginPath();
    self.context$.fillStyle = "black";
    self.context$.fillText(text.string(), r.x() + self.text_margin$ / 2, r.y() + self.text_margin$ / 4, 1000);
    self.context$.fill();
    return self.context$.restore();
  };

  with_styles(block, part) {
    var self = this;
    if (! (part == null)) {
      if (part.styles().size_M() > 0) {
        self.context$.save();
        part.styles().each(function(style) {
          if (Enso.System.test_type(style, "Pen")) {
            if (style.width()) {
              self.context$.lineWidth = style.width();
            }
            if (style.color()) {
              return self.context$.strokeStyle = self.makeColor(style.color());
            }
          } else if (Enso.System.test_type(style, "Font")) {
            return self.context$.font = self.makeFont(style);
          } else if (Enso.System.test_type(style, "Brush")) {
            return self.context$.fillStyle = self.makeColor(style.color());
          }
        });
        block();
        return self.context$.restore();
      } else {
        return block();
      }
    }
  };

  makeColor(c) {
    var self = this;
    return Enso.S("\#", self.to_byte(c.r()), self.to_byte(c.g()), self.to_byte(c.b()));
  };

  to_byte(v) {
    var self = this;
    return v.to_hex().rjust(2, "0");
  };

  makeFont(font) {
    var self = this, s;
    s = "";
    if (! (font.style() == null)) {
      s = (s + font.style()) + " ";
    }
    if (! (font.weight() == null)) {
      s = (s + font.weight()) + " ";
    }
    s = s + Enso.S(font.points(), "px");
    if (! (font.family() == null)) {
      s = (s + " ") + font.family();
    }
    return s;
  };
};

class Selection {
  static new(...args) { return new Selection(...args) };

  constructor(diagram, part, down) {
    var self = this;
    self.diagram$ = diagram;
    self.part$ = part;
    self.down$ = down;
  };

  do_mouse_down(e) {
    var self = this;
  };

  do_mouse_up() {
    var self = this;
  };

  do_move(e, down) {
    var self = this;
  };

  do_paint() {
    var self = this;
  };

  clear() {
    var self = this;
  };
};

class MoveShapeSelection extends Selection {
  static new(...args) { return new MoveShapeSelection(...args) };

  constructor(diagram, part, down) {
    super(diagram, part, down);
    var self = this;
    self.move_base$ = self.diagram$.boundary_fixed(part);
  };

  do_move(pnt, down) {
    var self = this;
    if (down) {
      self.diagram$.set_position(self.part$, self.move_base$.x() + pnt.x() - self.down$.x(), self.move_base$.y() + pnt.y() - self.down$.y());
      return self.diagram$.clear_refresh();
    }
  };

  do_paint() {
    var self = this;
  };

  to_s() {
    var self = this;
    return Enso.S("MOVE_SEL ", self.part$);
  };
};

class ConnectorSelection extends Selection {
  static new(...args) { return new ConnectorSelection(...args) };

  constructor(diagram, conn) {
    super(diagram, conn, true);
    var self = this;
    self.conn$ = conn;
    self.ce$ = null;
  };

  do_paint() {
    var self = this, size_V, p;
    self.diagram$.context().save();
    self.diagram$.context().fillStyle = self.diagram$.makeColor(self.diagram$.factory().Color(255, 0, 0));
    size_V = 8;
    p = self.conn$.path().get(0);
    self.diagram$.context().fillRect(p.x() + - size_V / 2, p.y() + - size_V / 2, size_V, size_V);
    p = self.conn$.path().get(- 1);
    self.diagram$.context().fillRect(p.x() + - size_V / 2, p.y() + - size_V / 2, size_V, size_V);
    return self.diagram$.context().restore();
  };

  do_mouse_down(pnt) {
    var self = this, size_V, pnt, p, r;
    size_V = 8;
    pnt = self.diagram$.factory().Point(pnt.x(), pnt.y());
    p = self.conn$.path().get(0);
    r = self.diagram$.factory().Rect(p.x() - size_V / 2, p.y() - size_V / 2, size_V, size_V);
    if (self.diagram$.rect_contains(r, pnt)) {
      self.ce$ = self.conn$.ends().get(0);
    } else {
      p = self.conn$.path().get(- 1);
      r = self.diagram$.factory().Rect(p.x() - size_V / 2, p.y() - size_V / 2, size_V, size_V);
      if (self.diagram$.rect_contains(r, pnt)) {
        self.ce$ = self.conn$.ends().get(1);
      } else {
        self.ce$ = null;
      }
    }
    return self.ce$;
  };

  do_move(pnt, down) {
    var self = this, bounds, x, y, angle, nx, ny;
    if (down && self.ce$) {
      bounds = self.diagram$.boundary_fixed(self.ce$.to());
      x = pnt.x() - bounds.x() + bounds.w() / 2;
      y = pnt.y() - bounds.y() + bounds.h() / 2;
      if (x == 0 && y == 0) {
        return null;
      } else {
        angle = Math.atan2(y, x);
        nx = self.normalize(Math.cos(angle));
        ny = self.normalize(Math.sin(angle));
        self.ce$.attach().set_x(nx);
        self.ce$.attach().set_y(ny);
        return self.diagram$.clear_refresh();
      }
    }
  };

  normalize(n) {
    var self = this, n;
    n = n * Math.sqrt(2);
    n = Enso.System.max(- 1, n);
    n = Enso.System.min(1, n);
    n = (n + 1) / 2;
    return n;
  };

  do_mouse_up() {
    var self = this;
    return self.ce$ = null;
  };

  to_s() {
    var self = this;
    return Enso.S("CONT_SEL ", self.conn$);
  };
};

class PointSelection extends Selection {
  static new(...args) { return new PointSelection(...args) };

  constructor(diagram, ce, lastSelection) {
    super(diagram, ce, true);
    var self = this;
    self.ce$ = ce;
    self.lastSelection$ = lastSelection;
  };

  to_s() {
    var self = this;
    return Enso.S("PNT_SEL ", self.ce$, "   ", self.lastSelection$, "ss");
  };
};

class EnsoPoint {
  static new(...args) { return new EnsoPoint(...args) };

  constructor(x, y) {
    var self = this;
    self.x$ = x;
    self.y$ = y;
  };

  x() { return this.x$ };
  set_x(val) { this.x$ = val };

  y() { return this.y$ };
  set_y(val) { this.y$ = val };
};

class EnsoRect {
  static new(...args) { return new EnsoRect(...args) };

  constructor(x, y, w, h) {
    var self = this;
    self.x$ = x;
    self.y$ = y;
    self.w$ = w;
    self.h$ = h;
  };

  x() { return this.x$ };
  set_x(val) { this.x$ = val };

  y() { return this.y$ };
  set_y(val) { this.y$ = val };

  w() { return this.w$ };
  set_w(val) { this.w$ = val };

  h() { return this.h$ };
  set_h(val) { this.h$ = val };
};

Diagram = {
  DiagramFrame: DiagramFrame,
  Selection: Selection,
  MoveShapeSelection: MoveShapeSelection,
  ConnectorSelection: ConnectorSelection,
  PointSelection: PointSelection,
  EnsoPoint: EnsoPoint,
  EnsoRect: EnsoRect,
};
module.exports = Diagram ;
