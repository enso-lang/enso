define(["core/system/load/load", "core/diagram/code/constraints", "core/schema/code/factory"], (function (Load, Constraints, Factory) {
  var Diagram;
  var DiagramFrame = MakeClass("DiagramFrame", null, [], (function () {
  }), (function (super$) {
    (this.initialize = (function (win, canvas, input, title) {
      var self = this;
      (title = (((typeof title) !== "undefined") ? title : "Diagram"));
      var canvasWidth, canvasHeight;
      (self.$.win = win);
      (self.$.canvas = canvas);
      (self.$.input = input);
      (self.$.context = self.$.canvas.getContext("2d"));
      (self.$.menu_id = 0);
      (self.$.selection = null);
      (self.$.mouse_down = false);
      (self.$.DIST = 4);
      (self.$.text_margin = 4);
      (self.$.defaultConnectorDist = 20);
      (self.$.cs = Constraints.ConstraintSystem.new());
      (self.$.factory = Factory.new(Load.load("diagram.schema")));
      (self.$.select_color = self.$.factory.Color(0, 255, 0));
      self.$.win.addEventListener("resize", self.resizeCanvas(), false);
      (canvasWidth = self.$.win.innerWidth);
      (canvasHeight = self.$.win.innerHeight);
      (self.$.canvas.width = canvasWidth);
      return (self.$.canvas.height = canvasHeight);
    }));
    (this.factory = (function () {
      return this.$.factory;
    }));
    (this.set_factory = (function (val) {
      (this.$.factory = val);
    }));
    (this.context = (function () {
      return this.$.context;
    }));
    (this.set_context = (function (val) {
      (this.$.context = val);
    }));
    (this.input = (function () {
      return this.$.input;
    }));
    (this.set_input = (function (val) {
      (this.$.input = val);
    }));
    (this.resizeCanvas = (function () {
      var self = this;
      return Proc.new((function () {
        var canvasWidth, bounds, canvasHeight;
        (canvasWidth = self.$.win.innerWidth);
        (canvasHeight = self.$.win.innerHeight);
        (self.$.canvas.width = canvasWidth);
        (self.$.canvas.height = canvasHeight);
        (bounds = self.boundary(self.$.root));
        if (bounds) {
          bounds.set_w(self.$.cs.value(canvasWidth));
          bounds.set_h(self.$.cs.value(canvasHeight));
          return self.clear_refresh();
        }
      }));
    }));
    (this.set_root = (function (root) {
      var self = this;
      (self.$.context.font = "13px sans-serif");
      (self.$.context.strokeStyle = "#000000");
      (self.$.context.textBaseline = "top");
      (self.$.context.textAlign = "left");
      (self.$.canvas.onmousedown = self.on_mouse_down());
      (self.$.canvas.onmousemove = self.on_move());
      (self.$.canvas.onmouseup = self.on_mouse_up());
      (self.$.canvas.ondblclick = self.on_double_click());
      root.finalize();
      (self.$.root = root);
      (self.$.boundaries = (new EnsoHash({
        
      })));
      (self.$.gridData = (new EnsoHash({
        
      })));
      self.do_constraints();
      return self.resizeCanvas();
    }));
    (this.getCursorPosition = (function (event) {
      var self = this;
      var rect, x, y;
      (rect = self.$.canvas.getBoundingClientRect());
      (x = (event.clientX - rect.left));
      (y = (event.clientY - rect.top));
      return self.$.factory.Point(x, y);
    }));
    (this.on_mouse_down = (function () {
      var self = this;
      return Proc.new((function (e) {
        var done, clear, pnt, select;
        (pnt = self.getCursorPosition(e));
        (self.$.mouse_down = true);
        (done = false);
        (clear = self.$.selection);
        if (e.ctrlKey) {
          self.on_right_down(pnt);
          (done = true);
        }
        else {
          if (self.$.selection) { 
            if (self.$.selection.do_mouse_down(pnt)) { 
              (done = true); 
            } 
            else {
                   self.$.selection.clear();
                   (self.$.selection = null);
                 } 
          } 
          else {
               }
        }
        if ((!done)) {
          (select = self.find_in_ui((function (x, container) {
            return ((container && container.Container_P()) && (container.direction() == 3));
          }), pnt));
          (done = self.set_selected_part(select, pnt));
        }
        if ((done || clear)) {
          return self.clear_refresh();
        }
      }));
    }));
    (this.on_mouse_up = (function () {
      var self = this;
      return Proc.new((function (e) {
        (self.$.mouse_down = false);
        if (self.$.selection) {
          return self.$.selection.do_mouse_up();
        }
      }));
    }));
    (this.on_move = (function () {
      var self = this;
      return Proc.new((function (e) {
        var pnt;
        (pnt = self.getCursorPosition(e));
        if (self.$.selection) {
          return self.$.selection.do_move(pnt, self.$.mouse_down);
        }
      }));
    }));
    (this.on_key = (function () {
      var self = this;
      return Proc.new((function (e) {
      }));
    }));
    (this.set_selected_part = (function (select, pnt) {
      var self = this;
      if (select) {
        if (select.Connector_P()) { 
          (self.$.selection = ConnectorSelection.new(self, select)); 
        }
        else { 
          (self.$.selection = MoveShapeSelection.new(self, select, EnsoPoint.new(pnt.x(), pnt.y())));
        }
        return true;
      }
    }));
    (this.find_in_ui = (function (filter, pnt) {
      var self = this;
      return self.find1(filter, self.$.root, null, pnt);
    }));
    (this.find1 = (function (filter, part, container, pnt) {
      var self = this;
      var b, out;
      if (part.Connector_P()) { 
        return self.findConnector(filter, part, container, pnt); 
      } 
      else {
             (b = self.boundary_fixed(part));
             if (b) {
               if (self.rect_contains(b, pnt)) {
                 (out = null);
                 if (part.Container_P()) { 
                   (out = part.items().find_first((function (sub) {
                     return self.find1(filter, sub, part, pnt);
                   }))); 
                 }
                 else { 
                   if (part.Shape_P()) { 
                     if (part.content()) {
                       (out = self.find1(filter, part.content(), part, pnt));
                     } 
                   } 
                   else {
                        }
                 }
                 if (((!out) && filter(part, container))) {
                   (out = part);
                 }
                 return out;
               }
             }
           }
    }));
    (this.findConnector = (function (filter, part, container, pnt) {
      var self = this;
      var from, obj;
      (obj = part.ends().find_first((function (e) {
        if (e.label()) {
          (obj = self.find1(filter, e.label(), container, pnt));
        }
        return obj;
      })));
      if ((obj == null)) {
        (from = null);
        part.path().each((function (to) {
          if ((!(from == null))) {
            if (((self.between(from.x(), pnt.x(), to.x()) && self.between(from.y(), pnt.y(), to.y())) && (self.dist_line(pnt, from, to) <= self.$.DIST))) {
              (obj = part);
            }
          }
          return (from = to);
        }));
      }
      return obj;
    }));
    (this.getSide = (function (cend) {
      var self = this;
      if ((cend.y() == 0)) { 
        return 0; 
      }
      else { 
        if ((cend.x() == 1)) { 
          return 1; 
        }
        else { 
          if ((cend.y() == 1)) { 
            return 2; 
          }
          else { 
            if ((cend.x() == 0)) { 
              return 3; 
            }
            else { 
              return puts("NO SIDE!!!!");
            }
          }
        }
      }
    }));
    (this.makeConstraintRect = (function () {
      var self = this;
      var left, bottom, top, right;
      (left = self.$.cs.value(0));
      (top = self.$.cs.value(0));
      (right = self.$.cs.value(0));
      (bottom = self.$.cs.value(0));
      return EnsoRect.new(left, top, right, bottom);
    }));
    (this.do_constraints = (function () {
      var self = this;
      return self.constrain(self.$.root, self.makeConstraintRect());
    }));
    (this.constrain = (function (part, rect) {
      var self = this;
      return self.with_styles((function () {
        if (part.Connector_P()) { 
          return self.constrainConnector(part); 
        } 
        else {
               self.send(("constrain" + part.schema_class().name()).to_sym(), part, rect);
               return self.$.boundaries._set(part._id(), rect);
             }
      }), part);
    }));
    (this.constrainPage = (function (part, rect) {
      var self = this;
      return self.constrain(self.page().content(), rect);
    }));
    (this.make_grid_constraints = (function (num) {
      var self = this;
      var oldVar, start, newVar, pos;
      (pos = []);
      (newVar = (oldVar = null));
      (start = 0);
      start.upto((function (i) {
        (newVar = self.$.cs.var(S("r", i, ""), 0));
        if (oldVar) {
          newVar.max(oldVar);
        }
        pos.push(newVar);
        return (oldVar = newVar);
      }), (num + 1));
      return pos;
    }));
    (this.constrainGrid = (function (grid, rect) {
      var self = this;
      var colPos, rowPos;
      (colPos = self.make_grid_constraints(grid.colNum()));
      (rowPos = self.make_grid_constraints(grid.rowNum()));
      return [grid.sides(), grid.tops(), grid.items()].each((function (group) {
        return group.each((function (item) {
          var col, newRect, left, bottom, top, row, right;
          (col = item.col());
          (row = item.row());
          (left = colPos._get(col));
          (top = rowPos._get(row));
          (right = colPos._get((col + 1)));
          (bottom = rowPos._get((row + 1)));
          (newRect = EnsoRect.new(left, top, right, bottom));
          return self.constrain(item.contents(), newRect);
        }));
      }));
    }));
    (this.constrainContainer = (function (part, rect) {
      var self = this;
      var newRect, left, top;
      (newRect = null);
      switch ((function () {
        return part.direction();
      })()) {
        case 5:
         return part.items().each((function (item) {
           return self.constrain(item, rect);
         }));
        case 3:
         (top = rect.top().add(0));
         (left = rect.left().add(0));
         return part.items().each((function (item) {
           var bottom, right;
           (bottom = self.$.cs.var(0));
           (right = self.$.cs.var(0));
           (newRect = EnsoRect.new(left, top, right, bottom));
           self.constrain(item, newRect);
           (top = top.add(30));
           (left = left.add(20));
           rect.bottom().max(newRect.bottom());
           return rect.right().max(newRect.right());
         }));
        case 2:
         (left = rect.left());
         part.items().each((function (item) {
           var right;
           (right = self.$.cs.var());
           right.max(left);
           (newRect = EnsoRect.new(left, rect.top(), right, rect.bottom()));
           self.constrain(item, newRect);
           return (left = newRect.right());
         }));
         return rect.right().max(newRect.right());
        case 1:
         (top = rect.top());
         part.items().each((function (item) {
           var bottom;
           (bottom = self.$.cs.var());
           bottom.max(top);
           (newRect = EnsoRect.new(rect.left(), top, rect.right(), bottom));
           self.constrain(item, newRect);
           return (top = newRect.bottom());
         }));
         return rect.bottom().max(newRect.bottom());
      }
          
    }));
    (this.constrainShape = (function (part, rect) {
      var self = this;
      var a, b, newRect, left, bottom, margin, top, right;
      (margin = (self.$.context.lineWidth * 6));
      switch ((function () {
        return part.kind();
      })()) {
        case "rounded":
         (a = self.$.cs.var("rnd1", (20 + margin)));
         (b = self.$.cs.var("rnd2", (20 + margin)));
         break;
        case "oval":
         (a = self.$.cs.var("pos1", margin));
         (b = self.$.cs.var("pos2", margin));
         break;
        case "box":
         (a = self.$.cs.var("box1", margin));
         (b = self.$.cs.var("box2", margin));
         break;
      }
          
      (top = rect.top());
      (left = rect.left());
      (bottom = self.$.cs.var());
      bottom.max(top);
      (right = self.$.cs.var());
      right.max(left);
      (newRect = EnsoRect.new(left.add(a), top.add(b), right, bottom));
      self.constrain(part.content(), newRect);
      rect.bottom().max(bottom.add(a));
      return rect.right().max(right.add(a));
    }));
    (this.constrainText = (function (part, rect) {
      var self = this;
      var info;
      (info = self.$.context.measureText(part.string()));
      rect.right().max(rect.left().add((info.width + self.$.text_margin)));
      return rect.bottom().max(rect.top().add(15));
    }));
    (this.constrainConnector = (function (part) {
      var self = this;
      return part.ends().each((function (ce) {
        var x, y, to, dynamic;
        (to = self.boundary(ce.to()));
        (dynamic = ce.attach().dynamic_update());
        (x = to.x().add(to.w().mul(dynamic.x())));
        (y = to.y().add(to.h().mul(dynamic.y())));
        self.$.boundaries._set(ce._id(), EnsoPoint.new(x, y));
        return self.constrainConnectorEnd(ce, x, y);
      }));
    }));
    (this.constrainConnectorEnd = (function (e, x, y) {
      var self = this;
      if (e.label()) {
        return self.constrain(e.label(), x, y);
      }
    }));
    (this.boundary = (function (shape) {
      var self = this;
      return self.$.boundaries._get(shape._id());
    }));
    (this.boundary_fixed = (function (shape) {
      var self = this;
      var r;
      (r = self.boundary(shape));
      if ((!(r == null))) {
        return EnsoRect.new(r.left().value(), r.top().value(), r.right().value(), r.bottom().value());
      }
    }));
    (this.position_fixed = (function (shape) {
      var self = this;
      var p;
      (p = self.boundary(shape));
      if ((!(p == null))) {
        return EnsoPoint.new(p.top().value(), p.left().value());
      }
    }));
    (this.set_position = (function (shape, x, y) {
      var self = this;
      var r;
      (r = self.boundary(shape));
      r.x().set_value(x);
      return r.y().set_value(y);
    }));
    (this.between = (function (a, b, c) {
      var self = this;
      return ((((a - self.$.DIST) <= b) && (b <= (c + self.$.DIST))) || (((c - self.$.DIST) <= b) && (b <= (a + self.$.DIST))));
    }));
    (this.rect_contains = (function (rect, pnt) {
      var self = this;
      return ((((rect.left() <= pnt.x()) && (pnt.x() <= rect.right())) && (rect.top() <= pnt.y())) && (pnt.y() <= rect.bottom()));
    }));
    (this.dist_line = (function (p0, p1, p2) {
      var self = this;
      var num, den;
      (num = (((p2.x() - p1.x()) * (p1.y() - p0.y())) - ((p1.x() - p0.x()) * (p2.y() - p1.y()))));
      (den = (Math.pow((p2.x() - p1.x()), 2) + Math.pow((p2.y() - p1.y()), 2)));
      return (num.abs() / Math.sqrt(den));
    }));
    (this.clear_refresh = (function () {
      var self = this;
      (self.$.context.fillStyle = "white");
      self.$.context.fillRect(0, 0, 5000, 5000);
      (self.$.context.fillStyle = "black");
      self.draw(self.$.root, 0);
      if (self.$.selection) {
        return self.$.selection.do_paint();
      }
    }));
    (this.draw = (function (part, n) {
      var self = this;
      (self.$.context.font = "13px sans-serif");
      (self.$.context.strokeStyle = "#000000");
      (self.$.context.textBaseline = "top");
      return self.with_styles((function () {
        return self.send(("draw" + part.schema_class().name()).to_sym(), part, (n + 1));
      }), part);
    }));
    (this.drawContainer = (function (part, n) {
      var self = this;
      var current;
      if ((part.direction() == 5)) {
        (current = (function () {
          if ((part.curent() == null)) { 
            return 0; 
          }
          else { 
            return part.current();
          }
        })());
        return self.draw(part.items()._get(current), (n + 1));
      }
      else {
        return part.items().each((function (item) {
          return self.draw(item, (n + 1));
        }));
      }
    }));
    (this.drawPage = (function (shape, n) {
      var self = this;
      var r;
      (r = self.boundary_fixed(shape));
      self.$.context.save();
      self.$.context.beginPath();
      (self.$.context.fillStyle = "black");
      self.$.context.fillText(shape.name(), (r.x() + 2), r.y());
      self.$.context.fill();
      self.$.context.restore();
      return self.draw(shape.content(), (n + 1));
    }));
    (this.drawGrid = (function (grid, n) {
      var self = this;
      return [grid.tops(), grid.sides(), grid.items()].each((function (group) {
        return group.each((function (item) {
          return self.draw(item.contents(), (n + 1));
        }));
      }));
    }));
    (this.drawCanvasRect = (function (r, margin) {
      var self = this;
      var m2;
      (m2 = (margin - (margin % 2)));
      self.$.context.save();
      self.$.context.rect((r.left() + (margin / 2)), (r.top() + (margin / 2)), (r.w() - m2), (r.h() - m2));
      (self.$.context.fillStyle = "Cornsilk");
      (self.$.context.shadowColor = "#999");
      (self.$.context.shadowBlur = 6);
      (self.$.context.shadowOffsetX = 2);
      (self.$.context.shadowOffsetY = 2);
      self.$.context.fill();
      self.$.context.stroke();
      return self.$.context.restore();
    }));
    (this.drawShape = (function (shape, n) {
      var self = this;
      var start, rx, ry, margin, anticlockwise, r, finish, x, y, rotation;
      (r = self.boundary_fixed(shape));
      if (r) {
        (margin = (self.$.context.lineWidth * 6));
        switch ((function () {
          return shape.kind();
        })()) {
          case "oval":
           (rx = (r.w() / 2));
           (ry = (r.h() / 2));
           (x = (r.x() + rx));
           (y = (r.y() + ry));
           (rotation = 0);
           (start = 0);
           (finish = (2 * Math.PI));
           (anticlockwise = false);
           self.$.context.save();
           (self.$.context.fillStyle = "Cornsilk");
           (self.$.context.shadowColor = "#999");
           (self.$.context.shadowBlur = 6);
           (self.$.context.shadowOffsetX = 2);
           (self.$.context.shadowOffsetY = 2);
           self.$.context.beginPath();
           self.$.context.ellipse(x, y, rx, ry, rotation, start, finish, anticlockwise);
           self.$.context.fill();
           self.$.context.restore();
           break;
          case "box":
           self.drawCanvasRect(r, margin);
           break;
        }
            
      }
      return self.draw(shape.content(), (n + 1));
    }));
    (this.drawConnector = (function (part, n) {
      var self = this;
      var sideFrom, ps, thetaFrom, e1, rTo, sideTo, thetaTo, pFrom, rFrom, e0, pTo;
      (e0 = part.ends()._get(0));
      (e1 = part.ends()._get(1));
      (rFrom = self.boundary_fixed(e0.to()));
      (rTo = self.boundary_fixed(e1.to()));
      switch ((function () {
        return e0.to().kind();
      })()) {
        case "oval":
         (thetaFrom = (-Math.atan2((e0.attach().top() - 0.5), (e0.attach().left() - 0.5))));
         (pFrom = EnsoPoint.new((rFrom.left() + (rFrom.w() * (0.5 + (Math.cos(thetaFrom) / 2)))), (rFrom.top() + (rFrom.h() * (0.5 - (Math.sin(thetaFrom) / 2))))));
         break;
        case "box":
         (pFrom = EnsoPoint.new((rFrom.top() + (rFrom.h() * e0.attach().x())), (rFrom.left() + (rFrom.w() * e0.attach().y()))));
         break;
        case "rounded":
         (pFrom = EnsoPoint.new((rFrom.top() + (rFrom.h() * e0.attach().x())), (rFrom.left() + (rFrom.w() * e0.attach().y()))));
         break;
      }
          
      switch ((function () {
        return e1.to().kind();
      })()) {
        case "oval":
         (thetaTo = (-Math.atan2((e1.attach().y() - 0.5), (e1.attach().x() - 0.5))));
         (pTo = EnsoPoint.new((rTo.left() + (rTo.w() * (0.5 + (Math.cos(thetaTo) / 2)))), (rTo.top() + (rTo.h() * (0.5 - (Math.sin(thetaTo) / 2))))));
         break;
        case "box":
         (pTo = EnsoPoint.new((rTo.left() + (rTo.w() * e1.attach().x())), (rTo.top() + (rTo.h() * e1.attach().y()))));
         break;
        case "rounded":
         (pTo = EnsoPoint.new((rTo.left() + (rTo.w() * e1.attach().x())), (rTo.top() + (rTo.h() * e1.attach().y()))));
         break;
      }
          
      (sideFrom = self.getSide(e0.attach()));
      (sideTo = self.getSide(e1.attach()));
      if ((sideFrom == sideTo)) { 
        (ps = self.simpleSameSide(pFrom, pTo, sideFrom)); 
      }
      else { 
        if ((((sideFrom - sideTo).abs() % 2) == 0)) { 
          (ps = self.simpleOppositeSide(pFrom, pTo, sideFrom)); 
        }
        else { 
          if ((e0.to() == e1.to())) { 
            (ps = self.sameObjectCorner(pFrom, pTo, sideFrom)); 
          }
          else { 
            (ps = self.simpleOrthogonalSide(pFrom, pTo, sideFrom));
          }
        }
      }
      ps.unshift(pFrom);
      ps.push(pTo);
      part.path().clear();
      ps.each((function (p) {
        return part.path().push(self.$.factory.Point(p.x(), p.y()));
      }));
      self.$.context.save();
      self.$.context.beginPath();
      ps.map((function (p) {
        return self.$.context.lineTo(p.x(), p.y());
      }));
      self.$.context.stroke();
      self.drawEnd(e0, e1, pFrom, pTo);
      self.drawEnd(e1, e0, pTo, pFrom);
      return self.$.context.restore();
    }));
    (this.drawEnd = (function (cend, other_end, r, s) {
      var self = this;
      var size, offsetY, arrow, rTo, index, angle, side, rFrom, offsetX, align;
      (side = self.getSide(cend.attach()));
      (rFrom = self.boundary_fixed(cend.to()));
      (rTo = self.boundary_fixed(other_end.to()));
      switch ((function () {
        return side;
      })()) {
        case 3:
         (angle = 0);
         (align = "right");
         (offsetX = (-1));
         if ((s.y() < r.y())) { 
           (offsetY = 0); 
         }
         else { 
           (offsetY = (-1));
         }
         break;
        case 2:
         (angle = (-90));
         (align = "left");
         (offsetX = 1);
         if ((r.x() < s.x())) { 
           (offsetY = 0); 
         }
         else { 
           (offsetY = (-1));
         }
         break;
        case 1:
         (angle = 0);
         (align = "left");
         (offsetX = 1);
         if ((s.y() < r.y())) { 
           (offsetY = 0); 
         }
         else { 
           (offsetY = (-1));
         }
         break;
        case 0:
         (angle = 90);
         (align = "left");
         (offsetX = 1);
         if ((s.x() < r.x())) { 
           (offsetY = 0); 
         }
         else { 
           (offsetY = (-1));
         }
         break;
      }
          
      self.with_styles((function () {
        var textHeight;
        self.$.context.save();
        self.$.context.translate(r.x(), r.y());
        self.$.context.rotate((((-Math.PI) * angle) / 180));
        (self.$.context.textAlign = align);
        (textHeight = 16);
        self.$.context.fillText(cend.label().string(), (offsetX * 3), (offsetY * textHeight));
        return self.$.context.restore();
      }), cend.label());
      if (((cend.arrow() == ">") || (cend.arrow() == "<"))) {
        self.$.context.save();
        (size = 5);
        (angle = (((-Math.PI) * (1 - side)) / 2));
        self.$.context.beginPath();
        (index = 0);
        (rFrom = self.boundary_fixed(cend.to()));
        (arrow = [EnsoPoint.new(0, 0), EnsoPoint.new(2, 1), EnsoPoint.new(2, (-1)), EnsoPoint.new(0, 0)].each((function (p) {
          var px, py;
          (px = ((Math.cos(angle) * p.x()) - (Math.sin(angle) * p.y())));
          (py = ((Math.sin(angle) * p.x()) + (Math.cos(angle) * p.y())));
          (px = ((px * size) + r.x()));
          (py = ((py * size) + r.y()));
          if ((index == 0)) { 
            self.$.context.moveTo(px, py); 
          }
          else { 
            self.$.context.lineTo(px, py);
          }
          return (index = (index + 1));
        })));
        self.$.context.closePath();
        self.$.context.fill();
        return self.$.context.restore();
      }
    }));
    (this.simpleSameSide = (function (a, b, d) {
      var self = this;
      var z;
      switch ((function () {
        return d;
      })()) {
        case 3:
         (z = System.min((a.x() - self.$.defaultConnectorDist), (b.x() - self.$.defaultConnectorDist)));
         return [EnsoPoint.new(z, a.y()), EnsoPoint.new(z, b.y())];
        case 2:
         (z = System.max((a.y() + self.$.defaultConnectorDist), (b.y() + self.$.defaultConnectorDist)));
         return [EnsoPoint.new(a.x(), z), EnsoPoint.new(b.x(), z)];
        case 1:
         (z = System.max((a.x() + self.$.defaultConnectorDist), (b.x() + self.$.defaultConnectorDist)));
         return [EnsoPoint.new(z, a.y()), EnsoPoint.new(z, b.y())];
        case 0:
         (z = System.min((a.y() - self.$.defaultConnectorDist), (b.y() - self.$.defaultConnectorDist)));
         return [EnsoPoint.new(a.x(), z), EnsoPoint.new(b.x(), z)];
      }
          
    }));
    (this.simpleOppositeSide = (function (a, b, d) {
      var self = this;
      var z;
      switch ((function () {
        return d;
      })()) {
        case 1:
         (z = self.average(a.x(), b.x()));
         return [EnsoPoint.new(z, a.y()), EnsoPoint.new(z, b.y())];
        case 3:
         (z = self.average(a.x(), b.x()));
         return [EnsoPoint.new(z, a.y()), EnsoPoint.new(z, b.y())];
        case 0:
         (z = self.average(a.y(), b.y()));
         return [EnsoPoint.new(a.x(), z), EnsoPoint.new(b.x(), z)];
        case 2:
         (z = self.average(a.y(), b.y()));
         return [EnsoPoint.new(a.x(), z), EnsoPoint.new(b.x(), z)];
      }
          
    }));
    (this.average = (function (m, n) {
      var self = this;
      return Integer(((m + n) / 2));
    }));
    (this.sameObjectCorner = (function (a, b, d) {
      var self = this;
      var m, z;
      switch ((function () {
        return d;
      })()) {
        case 1:
         if ((d == 1)) { 
           (z = (a.x() - self.$.defaultConnectorDist)); 
         }
         else { 
           (z = (a.x() + self.$.defaultConnectorDist));
         }
         if ((a.y() > b.y())) { 
           (m = (b.y() - self.$.defaultConnectorDist)); 
         }
         else { 
           (m = (b.y() + self.$.defaultConnectorDist));
         }
         return [EnsoPoint.new(z, a.y()), EnsoPoint.new(z, m), EnsoPoint.new(b.x(), m)];
        case 3:
         if ((d == 1)) { 
           (z = (a.x() - self.$.defaultConnectorDist)); 
         }
         else { 
           (z = (a.x() + self.$.defaultConnectorDist));
         }
         if ((a.y() > b.y())) { 
           (m = (b.y() - self.$.defaultConnectorDist)); 
         }
         else { 
           (m = (b.y() + self.$.defaultConnectorDist));
         }
         return [EnsoPoint.new(z, a.y()), EnsoPoint.new(z, m), EnsoPoint.new(b.x(), m)];
        case 0:
         if ((d == 0)) { 
           (z = (a.y() - self.$.defaultConnectorDist)); 
         }
         else { 
           (z = (a.y() + self.$.defaultConnectorDist));
         }
         if ((a.x() > b.x())) { 
           (m = (b.x() - self.$.defaultConnectorDist)); 
         }
         else { 
           (m = (b.x() + self.$.defaultConnectorDist));
         }
         return [EnsoPoint.new(a.x(), z), EnsoPoint.new(m, z), EnsoPoint.new(m, b.y())];
        case 2:
         if ((d == 0)) { 
           (z = (a.y() - self.$.defaultConnectorDist)); 
         }
         else { 
           (z = (a.y() + self.$.defaultConnectorDist));
         }
         if ((a.x() > b.x())) { 
           (m = (b.x() - self.$.defaultConnectorDist)); 
         }
         else { 
           (m = (b.x() + self.$.defaultConnectorDist));
         }
         return [EnsoPoint.new(a.x(), z), EnsoPoint.new(m, z), EnsoPoint.new(m, b.y())];
      }
          
    }));
    (this.simpleOrthogonalSide = (function (a, b, d) {
      var self = this;
      switch ((function () {
        return d;
      })()) {
        case 1:
         return [EnsoPoint.new(b.x(), a.y())];
        case 3:
         return [EnsoPoint.new(b.x(), a.y())];
        case 0:
         return [EnsoPoint.new(a.x(), b.y())];
        case 2:
         return [EnsoPoint.new(a.x(), b.y())];
      }
          
    }));
    (this.drawText = (function (text, n) {
      var self = this;
      var left, mid, r, top, right;
      (r = self.boundary_fixed(text));
      self.$.context.save();
      self.$.context.beginPath();
      (self.$.context.fillStyle = "black");
      (top = (r.top() + (self.$.text_margin / 4)));
      switch ((function () {
        return self.$.context.textAlign;
      })()) {
        case "right":
         puts("drawing right");
         (right = (r.right() - (self.$.text_margin / 2)));
         self.$.context.fillText(text.string(), right, top);
         break;
        case "center":
         puts("drawing center");
         (mid = ((r.left() + r.right()) / 2));
         self.$.context.fillText(text.string(), mid, top);
         break;
        default:
         (left = (r.left() + (self.$.text_margin / 2)));
         self.$.context.fillText(text.string(), left, top);
      }
          
      self.$.context.fill();
      return self.$.context.restore();
    }));
    (this.with_styles = (function (block, part) {
      var self = this;
      if ((!(part == null))) {
        if ((part.styles().size() > 0)) {
          self.$.context.save();
          part.styles().each((function (style) {
            if (style.Pen_P()) {
              if (style.width()) {
                (self.$.context.lineWidth = style.width());
              }
              if (style.color()) {
                return (self.$.context.strokeStyle = self.makeColor(style.color()));
              }
            }
            else {
              if (style.Font_P()) { 
                return (self.$.context.font = self.makeFont(style)); 
              }
              else { 
                if (style.Brush_P()) { 
                  return (self.$.context.fillStyle = self.makeColor(style.color())); 
                }
                else { 
                  if (style.Align_P()) { 
                    return (self.$.context.textAlign = style.kind()); 
                  } 
                  else {
                       }
                }
              }
            }
          }));
          block();
          return self.$.context.restore();
        }
        else {
          return block();
        }
      }
    }));
    (this.makeColor = (function (c) {
      var self = this;
      return S("\#", self.to_byte(c.r()), "", self.to_byte(c.g()), "", self.to_byte(c.b()), "");
    }));
    (this.to_byte = (function (v) {
      var self = this;
      return v.to_hex().rjust(2, "0");
    }));
    (this.makeFont = (function (font) {
      var self = this;
      var s;
      (s = "");
      if ((!(font.style() == null))) {
        (s = ((s + font.style()) + " "));
      }
      if ((!(font.weight() == null))) {
        (s = ((s + font.weight()) + " "));
      }
      (s = (s + S("", font.size(), "px")));
      if ((!(font.family() == null))) {
        (s = ((s + " ") + font.family()));
      }
      return s;
    }));
  }));
  var Selection = MakeClass("Selection", null, [], (function () {
  }), (function (super$) {
    (this.do_mouse_down = (function (e) {
      var self = this;
    }));
    (this.do_mouse_up = (function () {
      var self = this;
    }));
    (this.do_move = (function (e, down) {
      var self = this;
    }));
    (this.do_paint = (function () {
      var self = this;
    }));
    (this.clear = (function () {
      var self = this;
    }));
  }));
  var MoveShapeSelection = MakeClass("MoveShapeSelection", Selection, [], (function () {
  }), (function (super$) {
    (this.initialize = (function (diagram, part, down) {
      var self = this;
      (self.$.diagram = diagram);
      (self.$.part = part);
      (self.$.down = down);
      return (self.$.move_base = self.$.diagram.boundary_fixed(part));
    }));
    (this.do_move = (function (pnt, down) {
      var self = this;
      if (down) {
        self.$.diagram.set_position(self.$.part, (self.$.move_base.x() + (pnt.x() - self.$.down.x())), (self.$.move_base.y() + (pnt.y() - self.$.down.y())));
        return self.$.diagram.clear_refresh();
      }
    }));
    (this.do_paint = (function () {
      var self = this;
    }));
    (this.to_s = (function () {
      var self = this;
      return S("MOVE_SEL ", self.$.part, "");
    }));
  }));
  var ConnectorSelection = MakeClass("ConnectorSelection", Selection, [], (function () {
  }), (function (super$) {
    (this.initialize = (function (diagram, conn) {
      var self = this;
      (self.$.diagram = diagram);
      (self.$.conn = conn);
      return (self.$.ce = null);
    }));
    (this.do_paint = (function () {
      var self = this;
      var size, p;
      self.$.diagram.context().save();
      (self.$.diagram.context().fillStyle = self.$.diagram.makeColor(self.$.diagram.factory().Color(255, 0, 0)));
      (size = 8);
      (p = self.$.conn.path()._get(0));
      self.$.diagram.context().fillRect((p.x() + ((-size) / 2)), (p.y() + ((-size) / 2)), size, size);
      (p = self.$.conn.path()._get((-1)));
      self.$.diagram.context().fillRect((p.x() + ((-size) / 2)), (p.y() + ((-size) / 2)), size, size);
      return self.$.diagram.context().restore();
    }));
    (this.do_mouse_down = (function (pnt) {
      var self = this;
      var size, p, r;
      (size = 8);
      (pnt = self.$.diagram.factory().Point(pnt.x(), pnt.y()));
      (p = self.$.conn.path()._get(0));
      (r = self.$.diagram.factory().Rect((p.x() - (size / 2)), (p.y() - (size / 2)), size, size));
      if (self.$.diagram.rect_contains(r, pnt)) { 
        (self.$.ce = self.$.conn.ends()._get(0)); 
      } 
      else {
             (p = self.$.conn.path()._get((-1)));
             (r = self.$.diagram.factory().Rect((p.x() - (size / 2)), (p.y() - (size / 2)), size, size));
             if (self.$.diagram.rect_contains(r, pnt)) { 
               (self.$.ce = self.$.conn.ends()._get(1)); 
             }
             else { 
               (self.$.ce = null);
             }
           }
      return self.$.ce;
    }));
    (this.do_move = (function (pnt, down) {
      var self = this;
      var nx, ny, angle, bounds, x, y;
      if ((down && self.$.ce)) {
        (bounds = self.$.diagram.boundary_fixed(self.$.ce.to()));
        (x = (pnt.x() - (bounds.x() + (bounds.w() / 2))));
        (y = (pnt.y() - (bounds.y() + (bounds.h() / 2))));
        if (((x == 0) && (y == 0))) { 
          return null; 
        } 
        else {
               (angle = Math.atan2(y, x));
               (nx = self.normalize(Math.cos(angle)));
               (ny = self.normalize(Math.sin(angle)));
               self.$.ce.attach().set_x(nx);
               self.$.ce.attach().set_y(ny);
               return self.$.diagram.clear_refresh();
             }
      }
    }));
    (this.normalize = (function (n) {
      var self = this;
      (n = (n * Math.sqrt(2)));
      (n = System.max((-1), n));
      (n = System.min(1, n));
      (n = ((n + 1) / 2));
      return n;
    }));
    (this.do_mouse_up = (function () {
      var self = this;
      return (self.$.ce = null);
    }));
    (this.to_s = (function () {
      var self = this;
      return S("CONT_SEL ", self.$.conn, "");
    }));
  }));
  var PointSelection = MakeClass("PointSelection", Selection, [], (function () {
  }), (function (super$) {
    (this.initialize = (function (diagram, ce, lastSelection) {
      var self = this;
      (self.$.diagram = diagram);
      (self.$.ce = ce);
      return (self.$.lastSelection = lastSelection);
    }));
    (this.to_s = (function () {
      var self = this;
      return S("PNT_SEL ", self.$.ce, "   ", self.$.lastSelection, "ss");
    }));
  }));
  var EnsoPoint = MakeClass("EnsoPoint", null, [], (function () {
  }), (function (super$) {
    (this.initialize = (function (x, y) {
      var self = this;
      (self.$.x = x);
      return (self.$.y = y);
    }));
    (this.x = (function () {
      return this.$.x;
    }));
    (this.set_x = (function (val) {
      (this.$.x = val);
    }));
    (this.y = (function () {
      return this.$.y;
    }));
    (this.set_y = (function (val) {
      (this.$.y = val);
    }));
  }));
  var EnsoRect = MakeClass("EnsoRect", null, [], (function () {
  }), (function (super$) {
    (this.initialize = (function (l, t, r, b) {
      var self = this;
      (self.$.left = l);
      (self.$.top = t);
      (self.$.right = r);
      return (self.$.bottom = b);
    }));
    (this.left = (function () {
      return this.$.left;
    }));
    (this.set_left = (function (val) {
      (this.$.left = val);
    }));
    (this.top = (function () {
      return this.$.top;
    }));
    (this.set_top = (function (val) {
      (this.$.top = val);
    }));
    (this.right = (function () {
      return this.$.right;
    }));
    (this.set_right = (function (val) {
      (this.$.right = val);
    }));
    (this.bottom = (function () {
      return this.$.bottom;
    }));
    (this.set_bottom = (function (val) {
      (this.$.bottom = val);
    }));
    (this.w = (function () {
      var self = this;
      return (self.$.right - self.$.left);
    }));
    (this.h = (function () {
      var self = this;
      return (self.$.bottom - self.$.top);
    }));
  }));
  (Diagram = {
    EnsoRect: EnsoRect,
    EnsoPoint: EnsoPoint,
    Selection: Selection,
    DiagramFrame: DiagramFrame,
    ConnectorSelection: ConnectorSelection,
    MoveShapeSelection: MoveShapeSelection,
    PointSelection: PointSelection
  });
  return Diagram;
}));