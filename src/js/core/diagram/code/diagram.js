define(["core/system/load/load", "core/diagram/code/constraints", "core/schema/code/factory"], (function (Load, Constraints, Factory) {
  var Diagram;
  var DiagramFrame = MakeClass("DiagramFrame", null, [], (function () {
  }), (function (super$) {
    (this.initialize = (function (win, canvas, context, title) {
      var self = this;
      (title = (((typeof title) !== "undefined") ? title : "Diagram"));
      (self.$.win = win);
      (self.$.canvas = canvas);
      (self.$.context = context);
      (self.$.menu_id = 0);
      (self.$.selection = null);
      (self.$.mouse_down = false);
      (self.$.DIST = 4);
      (self.$.defaultConnectorDist = 20);
      (self.$.cs = Constraints.ConstraintSystem.new());
      (self.$.factory = Factory.new(Load.load("diagram.schema")));
      return (self.$.select_color = self.$.factory.Color(0, 255, 0));
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
    (this.on_open = (function () {
      var self = this;
      var path, dialog, content, extension;
      (dialog = FileDialog.new(self, "Choose a file", "", "", "Diagrams (*.diagram;)|*.diagram;"));
      if ((dialog.show_modal() == self.ID_OK())) {
        (path = dialog.get_path());
        (extension = File.extname(path));
        if ((extension != "diagram")) {
          self.raise("File is not a diagram");
        }
        (content = Load(dialog.get_path()));
        return self.set_root(content);
      }
    }));
    (this.set_root = (function (root) {
      var self = this;
      (self.$.canvas.onmousedown = self.on_mouse_down());
      (self.$.canvas.onmousemove = self.on_move());
      (self.$.canvas.onmouseup = self.on_mouse_up());
      root.finalize();
      (self.$.root = root);
      (self.$.positions = (new EnsoHash({
        
      })));
      return self.clear_refresh();
    }));
    (this.clear_refresh = (function () {
      var self = this;
      (self.$.context.fillStyle = "white");
      self.$.context.fillRect(0, 0, 1000, 1000);
      (self.$.context.fillStyle = "black");
      (self.$.context.lineStyle = "red");
      (self.$.context.font = "14pt sans-serif");
      return self.paint();
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
        var done, pnt, select, subselect;
        (pnt = self.getCursorPosition(e));
        puts(S("DOWN ", pnt.x(), " ", pnt.y(), ""));
        (self.$.context.fillStyle = "#FF0000");
        self.$.context.fillRect(pnt.x(), pnt.y(), 4, 4);
        (self.$.mouse_down = true);
        (done = false);
        if (self.$.selection) {
          (subselect = self.$.selection.do_mouse_down(pnt));
          if ((subselect == "cancel")) {
            (self.$.selection = null);
            (done = true);
          }
          else {
            if (subselect) {
              (self.$.selection = subselect);
              (done = true);
            } else {
            }
          }
        }
        if ((!done)) {
          (select = self.find_in_ui((function (x) {
            var val;
            (val = ((self.$.find_container && self.$.find_container.Container_P()) && (self.$.find_container.direction() == 3)));
            return val;
          }), pnt));
          return self.set_selection(select, pnt);
        }
      }));
    }));
    (this.on_mouse_up = (function () {
      var self = this;
      return Proc.new((function (e) {
        return (self.$.mouse_down = false);
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
    (this.clear_selection = (function () {
      var self = this;
      if (self.$.selection) { 
        return (self.$.selection = self.$.selection.clear()); 
      }
      else { 
        return (self.$.selection = null);
      }
    }));
    (this.set_selection = (function (select, pnt) {
      var self = this;
      self.clear_selection();
      if (select) {
        if (select.Connector_P()) { 
          (self.$.selection = ConnectorSelection.new(self, select)); 
        }
        else { 
          (self.$.selection = MoveShapeSelection.new(self, select, EnsoPoint.new(pnt.x(), pnt.y())));
        }
        return self.clear_refresh();
      }
    }));
    (this.find_in_ui = (function (filter, pnt) {
      var self = this;
      return self.find1(filter, self.$.root, pnt);
    }));
    (this.find1 = (function (filter, part, pnt) {
      var self = this;
      var b, old_container, out;
      if (part.Connector_P()) { 
        return self.findConnector(filter, part, pnt); 
      } 
      else {
             (b = self.boundary_fixed(part));
             if ((!(b == null))) {
               try {if (self.rect_contains(b, pnt)) {
                 (old_container = self.$.find_container);
                 (self.$.find_container = part);
                 (out = null);
                 if (part.Container_P()) {
                   (out = part.items().find((function (sub) {
                     return self.find1(filter, sub, pnt);
                   })));
                   if (((!out) && filter(part))) {
                     (out = part);
                   }
                 }
                 else {
                   if (part.Shape_P()) { 
                     if (part.content()) {
                       (out = self.find1(filter, part.content(), pnt));
                     } 
                   } 
                   else {
                        }
                 }
                 (self.$.find_container = old_container);
                 if (out) { 
                   return out; 
                 }
                 else { 
                   if (filter(part)) {
                     return part;
                   }
                 }
               }
                    
               }
               catch (caught$3666) {
                 
                   if ((caught$3666 instanceof Exception)) { 
                     return (function (e) {
                       puts("ERROR DURING FIND!");
                     })(caught$3666); 
                   }
                   else { 
                     ;
                   }
               }
             }
           }
    }));
    (this.findConnector = (function (filter, part, pnt) {
      var self = this;
      var from, obj;
      (obj = part.ends().find((function (e) {
        if (e.label()) {
          (obj = self.find1(filter, e.label(), pnt));
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
      if (obj) {
        puts(S("FindCon ", obj.to_s(), ""));
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
    (this.do_constraints = (function () {
      var self = this;
      return self.constrain(self.$.root, self.$.cs.value(0), self.$.cs.value(0));
    }));
    (this.constrain = (function (part, x, y) {
      var self = this;
      var h, w;
      (w = null);
      (h = null);
      self.with_styles((function () {
        if (part.Connector_P()) { 
          return self.constrainConnector(part); 
        } 
        else {
               (w = self.$.cs.value(0));
               (h = self.$.cs.value(0));
               self.send(("constrain" + part.schema_class().name()).to_sym(), part, x, y, w, h);
               return self.$.positions._set(part, EnsoRect.new(x, y, w, h));
             }
      }), part);
      if ((!(w == null))) {
        return [w, h];
      }
    }));
    (this.constrainContainer = (function (part, basex, basey, width, height) {
      var self = this;
      var otherpos, pos, x, y;
      (pos = self.$.cs.value(0));
      (otherpos = self.$.cs.value(0));
      (x = basex.add(0));
      (y = basey.add(0));
      part.items().each_with_index((function (item, i) {
        var h, info, w;
        (info = self.constrain(item, x, y));
        if ((!(info == null))) {
          (w = info._get(0));
          (h = info._get(1));
          switch ((function () {
            return part.direction();
          })()) {
            case 3:
             (pos = pos.add(w));
             (otherpos = otherpos.add(h));
             (x = basex.add(pos));
             (y = basey.add(otherpos));
             width.max(x.add(w));
             return height.max(y.add(h));
            case 2:
             (pos = pos.add(w));
             (x = basex.add(pos));
             return height.max(h);
            case 1:
             (pos = pos.add(h));
             (y = basey.add(pos));
             return width.max(w);
          }
              
        }
      }));
      switch ((function () {
        return part.direction();
      })()) {
        case 2:
         return width.max(pos);
        case 1:
         return height.max(pos);
      }
          
    }));
    (this.constrainShape = (function (part, x, y, width, height) {
      var self = this;
      var a, b, ow, sq2, oh, info, margin;
      switch ((function () {
        return part.kind();
      })()) {
        case "rounded":
         (a = self.$.cs.var("rnd1", 20));
         (b = self.$.cs.var("rnd2", 20));
         break;
        case "oval":
         (a = self.$.cs.var("pos1", 0));
         (b = self.$.cs.var("pos2", 0));
         break;
        case "box":
         (a = self.$.cs.var("box1", 0));
         (b = self.$.cs.var("box2", 0));
         break;
      }
          
      (margin = self.$.context.lineWidth);
      (a = a.add(margin));
      (b = b.add(margin));
      (info = self.constrain(part.content(), x.add(a), y.add(b)));
      (ow = info._get(0));
      (oh = info._get(1));
      if ((part.kind() == "oval")) {
        (sq2 = (2 * Math.sqrt(2.0)));
        a.max(ow.div(sq2));
        b.max(oh.div(sq2));
        a.max(b);
      }
      width.max(ow.add(a.mul(2)));
      return height.max(oh.add(b.mul(2)));
    }));
    (this.constrainText = (function (part, x, y, width, height) {
      var self = this;
      var info;
      (info = self.$.context.measureText(part.string()));
      width.max(info.width);
      return height.max(15);
    }));
    (this.constrainConnector = (function (part) {
      var self = this;
      return part.ends().each((function (ce) {
        var x, y, to, dynamic;
        (to = self.$.positions._get(ce.to()));
        (dynamic = ce.attach().dynamic_update());
        (x = to.x().add(to.w().mul(dynamic.x())));
        (y = to.y().add(to.h().mul(dynamic.y())));
        self.$.positions._set(ce, EnsoPoint.new(x, y));
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
      return self.$.positions._get(shape);
    }));
    (this.boundary_fixed = (function (shape) {
      var self = this;
      var r;
      (r = self.boundary(shape));
      if ((!(r == null))) {
        return EnsoRect.new(r.x().value(), r.y().value(), r.w().value(), r.h().value());
      }
    }));
    (this.position = (function (shape) {
      var self = this;
      return self.$.positions._get(shape);
    }));
    (this.position_fixed = (function (shape) {
      var self = this;
      var p;
      (p = self.position(shape));
      if ((!(p == null))) {
        return EnsoPoint.new(p.x().value(), p.y().value());
      }
    }));
    (this.set_position = (function (shape, x, y) {
      var self = this;
      self.$.positions._get(shape).x().set_value(x);
      return self.$.positions._get(shape).y().set_value(y);
    }));
    (this.between = (function (a, b, c) {
      var self = this;
      return ((((a - self.$.DIST) <= b) && (b <= (c + self.$.DIST))) || (((c - self.$.DIST) <= b) && (b <= (a + self.$.DIST))));
    }));
    (this.rect_contains = (function (rect, pnt) {
      var self = this;
      return ((((rect.x() <= pnt.x()) && (pnt.x() <= (rect.x() + rect.w()))) && (rect.y() <= pnt.y())) && (pnt.y() <= (rect.y() + rect.h())));
    }));
    (this.dist_line = (function (p0, p1, p2) {
      var self = this;
      var num, den;
      (num = (((p2.x() - p1.x()) * (p1.y() - p0.y())) - ((p1.x() - p0.x()) * (p2.y() - p1.y()))));
      (den = (Math.pow((p2.x() - p1.x()), 2) + Math.pow((p2.y() - p1.y()), 2)));
      return (num.abs() / Math.sqrt(den));
    }));
    (this.paint = (function () {
      var self = this;
      if ((self.$.positions.size() == 0)) {
        self.do_constraints();
      }
      self.draw(self.$.root);
      if (self.$.selection) {
        return self.$.selection.do_paint();
      }
    }));
    (this.draw = (function (part) {
      var self = this;
      (self.$.context.textBaseline = "top");
      return self.with_styles((function () {
        return self.send(("draw" + part.schema_class().name()).to_sym(), part);
      }), part);
    }));
    (this.drawContainer = (function (part) {
      var self = this;
      var r, len;
      if ((part.direction() == 3)) {
        (r = self.boundary_fixed(part));
        self.$.context.strokeRect(r.x(), r.y(), r.w(), r.h());
      }
      (len = (part.items().size() - 1));
      return len.downto((function (i) {
        return self.draw(part.items()._get(i));
      }), 0);
    }));
    (this.drawShape = (function (shape) {
      var self = this;
      var start, m2, rx, ry, margin, anticlockwise, r, finish, x, y, rotation;
      (r = self.boundary_fixed(shape));
      (margin = self.$.context.lineWidth);
      (m2 = (margin - (margin % 2)));
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
         self.$.context.ellipse(x, y, rx, ry, rotation, start, finish, anticlockwise);
         self.$.context.stroke();
         break;
        case "box":
         self.$.context.strokeRect((r.x() + (margin / 2)), (r.y() + (margin / 2)), (r.w() - m2), (r.h() - m2));
         break;
      }
          
      return self.draw(shape.content());
    }));
    (this.drawConnector = (function (part) {
      var self = this;
      var sideFrom, ps, e1, rTo, sideTo, pFrom, rFrom, e0, pTo;
      (e0 = part.ends()._get(0));
      (e1 = part.ends()._get(1));
      (rFrom = self.boundary_fixed(e0.to()));
      (rTo = self.boundary_fixed(e1.to()));
      (pFrom = EnsoPoint.new((rFrom.x() + (e0.attach().x() * rFrom.w())), (rFrom.y() + (e0.attach().y() * rFrom.h()))));
      (pTo = EnsoPoint.new((rTo.x() + (e1.attach().x() * rTo.w())), (rTo.y() + (e1.attach().y() * rTo.h()))));
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
      self.$.context.beginPath();
      ps.map((function (p) {
        return self.$.context.lineTo(p.x(), p.y());
      }));
      self.$.context.stroke();
      self.drawEnd(e0);
      return self.drawEnd(e1);
    }));
    (this.drawEnd = (function (cend) {
      var self = this;
      var size, align, arrow, angle, pos, side, lineHeight, rFrom, r, index;
      (side = self.getSide(cend.attach()));
      (rFrom = self.boundary_fixed(cend.to()));
      (r = EnsoPoint.new((rFrom.x() + (cend.attach().x() * rFrom.w())), (rFrom.y() + (cend.attach().y() * rFrom.h()))));
      if (r) {
        switch ((function () {
          return side;
        })()) {
          case 3:
           (angle = 0);
           (align = "right");
           break;
          case 2:
           (angle = (-90));
           (align = "left");
           break;
          case 1:
           (angle = 0);
           (align = "left");
           break;
          case 0:
           (angle = 90);
           (align = "left");
           break;
        }
            
        (lineHeight = 10);
        self.with_styles((function () {
          self.$.context.save();
          self.$.context.translate(r.x(), r.y());
          self.$.context.rotate((((-Math.PI) * angle) / 180));
          (self.$.context.textAlign = align);
          self.$.context.fillText(cend.label().string(), 0, 0);
          return self.$.context.restore();
        }), cend.label());
      }
      if (((cend.arrow() == ">") || (cend.arrow() == "<"))) {
        (size = 5);
        (angle = (((-Math.PI) * (1 - side)) / 2));
        self.$.context.beginPath();
        (index = 0);
        (rFrom = self.boundary_fixed(cend.to()));
        (pos = EnsoPoint.new((rFrom.x() + (cend.attach().x() * rFrom.w())), (rFrom.y() + (cend.attach().y() * rFrom.h()))));
        (arrow = [EnsoPoint.new(0, 0), EnsoPoint.new(2, 1), EnsoPoint.new(2, (-1)), EnsoPoint.new(0, 0)].each((function (p) {
          var px, py;
          (px = ((Math.cos(angle) * p.x()) - (Math.sin(angle) * p.y())));
          (py = ((Math.sin(angle) * p.x()) + (Math.cos(angle) * p.y())));
          (px = ((px * size) + pos.x()));
          (py = ((py * size) + pos.y()));
          if ((index == 0)) { 
            self.$.context.moveTo(px, py); 
          }
          else { 
            self.$.context.lineTo(px, py);
          }
          return (index = (index + 1));
        })));
        self.$.context.closePath();
        return self.$.context.fill();
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
    (this.drawText = (function (text) {
      var self = this;
      var r;
      (r = self.boundary_fixed(text));
      return self.$.context.fillText(text.string(), r.x(), r.y());
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
                     }
              }
            }
          }));
          if ((self.$.selection && self.$.selection.is_selected(part))) {
            (self.$.context.stokeStyle = self.makeColor(self.$.select_color));
          }
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
  var MoveShapeSelection = MakeClass("MoveShapeSelection", null, [], (function () {
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
    (this.is_selected = (function (check) {
      var self = this;
      return (self.$.part == check);
    }));
    (this.do_paint = (function () {
      var self = this;
      (self.$.diagram.context().strokeStyle = "#FF0000");
      return self.$.diagram.draw(self.$.part);
    }));
    (this.do_mouse_down = (function (e) {
      var self = this;
    }));
    (this.clear = (function () {
      var self = this;
    }));
  }));
  var ConnectorSelection = MakeClass("ConnectorSelection", null, [], (function () {
  }), (function (super$) {
    (this.initialize = (function (diagram, conn) {
      var self = this;
      (self.$.diagram = diagram);
      return (self.$.conn = conn);
    }));
    (this.is_selected = (function (check) {
      var self = this;
      return (self.$.conn == check);
    }));
    (this.do_paint = (function () {
      var self = this;
      var size, p;
      (self.$.diagram.context().fillStyle = self.$.diagram.makeColor(self.$.diagram.factory().Color(255, 0, 0)));
      (size = 8);
      (p = self.$.conn.path()._get(0));
      self.$.diagram.context().fillRect((p.x() + ((-size) / 2)), (p.y() + ((-size) / 2)), size, size);
      (p = self.$.conn.path()._get((-1)));
      self.$.diagram.context().fillRect((p.x() + ((-size) / 2)), (p.y() + ((-size) / 2)), size, size);
      return self.$.conn.path().each((function (p) {
      }));
    }));
    (this.do_mouse_down = (function (pnt) {
      var self = this;
      var size, p, r;
      (size = 8);
      (pnt = self.$.diagram.factory().Point(pnt.x(), pnt.y()));
      (p = self.$.conn.path()._get(0));
      (r = self.$.diagram.factory().Rect((p.x() - (size / 2)), (p.y() - (size / 2)), size, size));
      if (self.$.diagram.rect_contains(r, pnt)) { 
        return PointSelection.new(self.$.diagram, self.$.conn.ends()._get(0), self); 
      } 
      else {
             (p = self.$.conn.path()._get((-1)));
             (r = self.$.diagram.factory().Rect((p.x() - (size / 2)), (p.y() - (size / 2)), size, size));
             if (self.$.diagram.rect_contains(r, pnt)) {
               return PointSelection.new(self.$.diagram, self.$.conn.ends()._get(1), self);
             }
           }
    }));
    (this.do_move = (function (e, down) {
      var self = this;
    }));
    (this.clear = (function () {
      var self = this;
    }));
  }));
  var PointSelection = MakeClass("PointSelection", null, [], (function () {
  }), (function (super$) {
    (this.initialize = (function (diagram, ce, selection) {
      var self = this;
      (self.$.diagram = diagram);
      (self.$.ce = ce);
      return (self.$.selection = selection);
    }));
    (this.is_selected = (function (check) {
      var self = this;
      return (self.$.ce == check);
    }));
    (this.do_paint = (function () {
      var self = this;
      var size, pos;
      (self.$.diagram.context().fillStyle = self.$.diagram.makeColor(self.$.diagram.factory().Color(0, 0, 255)));
      (size = 8);
      (pos = self.$.diagram.position_fixed(self.$.ce));
      return self.$.diagram.context().fillRect((pos.x() - (size / 2)), (pos.y() - (size / 2)), size, size);
    }));
    (this.do_mouse_down = (function (e) {
      var self = this;
    }));
    (this.do_move = (function (pnt, down) {
      var self = this;
      var nx, ny, angle, bounds, x, y;
      if (down) {
        (bounds = self.$.diagram.boundary_fixed(self.$.ce.to()));
        (x = (pnt.x() - (bounds.x() + (bounds.w() / 2))));
        (y = (pnt.y() - (bounds.y() + (bounds.h() / 2))));
        if (((x == 0) && (y == 0))) { 
          return null; 
        } 
        else {
               puts(S("FROM ", x, " ", y, ""));
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
    (this.clear = (function () {
      var self = this;
      return self.$.selection;
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
    (this.initialize = (function (x, y, w, h) {
      var self = this;
      (self.$.x = x);
      (self.$.y = y);
      (self.$.w = w);
      return (self.$.h = h);
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
    (this.w = (function () {
      return this.$.w;
    }));
    (this.set_w = (function (val) {
      (this.$.w = val);
    }));
    (this.h = (function () {
      return this.$.h;
    }));
    (this.set_h = (function (val) {
      (this.$.h = val);
    }));
  }));
  (Diagram = {
    EnsoRect: EnsoRect,
    EnsoPoint: EnsoPoint,
    DiagramFrame: DiagramFrame,
    ConnectorSelection: ConnectorSelection,
    MoveShapeSelection: MoveShapeSelection,
    PointSelection: PointSelection
  });
  return Diagram;
}));