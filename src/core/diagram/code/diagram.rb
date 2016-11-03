require 'core/system/load/load'
require 'core/diagram/code/constraints'
require 'core/schema/code/factory'


module Diagram

  class DiagramFrame
    def initialize(win, canvas, input, title = 'Diagram')
      @win = win
      @canvas = canvas
      @input = input
      @context = @canvas.getContext('2d')
     # @win.title_ = title
      
      @menu_id = 0
      @selection = nil
      @mouse_down = false
      @DIST = 4
      @defaultConnectorDist = 20
      @cs = Constraints::ConstraintSystem.new
      @factory = Factory.new(Load::load('diagram.schema'))
      @select_color = @factory.Color(0, 255, 0)

      # Register an event listener to
      # call the resizeCanvas() function each time
      # the window is resized.
      @win.addEventListener('resize', self.resizeCanvas(), false)

      canvasWidth = @win.innerWidth_
      canvasHeight = @win.innerHeight_
      @canvas.width_ = canvasWidth
      @canvas.height_ = canvasHeight
    end
    
    attr_accessor :factory
    attr_accessor :context
    attr_accessor :input
    
    # Runs each time the DOM window resize event fires.
    # Resets the canvas dimensions to match window,
    # then draws the new borders accordingly.
    def resizeCanvas()
      Proc.new {
        canvasWidth = @win.innerWidth_
        canvasHeight = @win.innerHeight_
        @canvas.width_ = canvasWidth
        @canvas.height_ = canvasHeight
        bounds = boundary(@root)
        if bounds
          bounds.w = @cs.value(canvasWidth)
          bounds.h = @cs.value(canvasHeight)
          clear_refresh
        end
      }
    end
                
    def set_root(root)
      @context.font_ = "13px sans-serif"
      @context.strokeStyle_ = "#000000"
      @context.textBaseline_ = "top"
    
      @canvas.onmousedown_ = on_mouse_down
      @canvas.onmousemove_ = on_move
      @canvas.onmouseup_ = on_mouse_up
      @canvas.ondblclick_ = on_double_click
                    
      root.finalize
      @root = root
      @positions = {}
      do_constraints
      # Draw canvas border for the first time.
      resizeCanvas
    end
  
    
    # ------- event handling -------  
   
    def getCursorPosition(event)
      rect = @canvas.getBoundingClientRect
      x = event.clientX_ - rect.left_
      y = event.clientY_ - rect.top_
      @factory.Point(x, y)
    end
  
    def on_mouse_down
      Proc.new { |e|
        pnt = getCursorPosition(e)
        #puts "DOWN #{pnt.x} #{pnt.y}"
        
        @mouse_down = true
        done = false
        clear = @selection
        if e.ctrlKey_ 
          # do an inplace menu
          on_right_down(pnt)
          done = true
        elsif @selection
          if @selection.do_mouse_down(pnt)
            done = true
          else
            @selection.clear
            @selection = nil
          end
        end
        if !done
          select = find_in_ui(pnt) do |x, container|
            #find something contained in a graph, which is dragable
            container && container.Container? && container.direction == 3 
            #puts "#{x} => #{val}"
          end
          #puts "FIND #{select}"
          done = set_selected_part(select, pnt)
        end
        if done or clear
           clear_refresh
        end
      }
    end
    
    def on_mouse_up
      Proc.new { |e|
        @mouse_down = false
        @selection.do_mouse_up if @selection
      }
    end
  
    def on_move
      Proc.new { |e|
        pnt = getCursorPosition(e)
        #puts "MOUSE move #{pnt.x}, #{pnt.y}"
        @selection.do_move(pnt, @mouse_down) if @selection
      }
    end
  
    def on_key
      Proc.new { |e|
      }
    end
  
    # ------- selections -------      
      
    def set_selected_part(select, pnt)
      if select
        if select.Connector?
          @selection = ConnectorSelection.new(self, select)
        else
          @selection = MoveShapeSelection.new(self, select, EnsoPoint.new(pnt.x, pnt.y))
        end
        true
      end
    end
    
    # ---- finding ------
    def find_in_ui(pnt, &filter)
      find1(@root, nil, pnt, &filter)
    end
    
    def find1(part, container, pnt, &filter)
      if part.Connector?
        findConnector(part, container, pnt, &filter)
      else
        b = boundary_fixed(part)
        if b
          # puts "FIND #{part}: #{b.x} #{b.y} #{b.w} #{b.h}"
          if rect_contains(b, pnt)
            out = nil
            if part.Container?
              out = part.items.find_first do |sub|
                find1(sub, part, pnt, &filter)
              end
            elsif part.Shape?
              out = find1(part.content, part, pnt, &filter) if part.content
            end
            out = part if !out && filter.call(part, container)
            out
          end
        end
      end
    end
      
    def findConnector(part, container, pnt, &filter)
      obj = part.ends.find_first do |e|
        if e.label
          obj = find1(e.label, container, pnt, &filter)
        end
        obj
      end
      if obj.nil?
        from = nil
        part.path.each do |to|
          if !from.nil?
            #puts "  LINE (#{from.x},#{from.y}) (#{to.x},#{to.y}) with (#{pnt.x},#{pnt.y})"
            if between(from.x, pnt.x, to.x) && between(from.y, pnt.y, to.y) && dist_line(pnt, from, to) <= @DIST
              obj = part
            end
          end
          from = to
        end
      end
      #puts "FindCon #{obj.to_s}" if obj
      obj
    end
  
    # ----- constrain -----
# a path is specified by a constraint system
#   the end is connected to a position on the part (h,w) 
#       where (h==0 || h==1) || (w==0 || w==1)
#   these define the "side" of the connection

    # sides are labeld top=0, right=1, bottom=2, left=3  
    def getSide(cend)
      if cend.y == 0 #top
        0 
      elsif cend.x == 1 #right
        1 
      elsif cend.y == 1 #bottom
        2 
      elsif cend.x == 0 #left
        3 
      else
        puts "NO SIDE!!!!"
      end
    end
  
#   the path depends on the orientation. There are three cases:
#     opp:   a--+
#               |
#               +--b
#       
#                 var:    a--+
#                            |
#                      +-----+
#                      |
#                      +--b
#
#                 var: +----------+
#                      |          |
#                      +--a    b--+
#
#     orth:  a--+    if a.P + a.PW + a.minP <= b.P + attach.P
#               |
#               b
#       
#                 var:    a--+     
#                            |
#                      +-----+
#                      |
#                      b
#
#                 var: +------+    
#                      |      |
#                      b   a--+
#
#     same:  a--+
#               |
#            b--+
#       
#                 var: b--+   a--+
#                         |      |
#                         +------+
#
#  but these can be in any orientation.
    
    def do_constraints
      constrain(@root, @cs.value(0), @cs.value(0)) 
    end
    
    def constrain(part, x, y)
      w = nil
      h = nil
      with_styles(part) do 
        if part.Connector?
          constrainConnector(part)
        else
          w = @cs.value(0)
          h = @cs.value(0)
          send(("constrain" + part.schema_class.name).to_sym, part, x, y, w, h)
          @positions[part._id] = EnsoRect.new(x, y, w, h)
        end
      end
      [w, h] if !w.nil?
    end

    def constrainGrid(part, basex, basey, width, height)
  
  
  	end
  	
    def constrainContainer(part, basex, basey, width, height)
      pos = @cs.value(0)
      otherpos = @cs.value(0)
      x = basex.add(0)
      y = basey.add(0)
      #puts "CONTAINER #{width.to_s}, #{height.to_s}"
      part.items.each_with_index do |item, i|
        info = constrain(item, x, y)
        if !info.nil?
          w = info[0]
          h = info[1]
          #puts "ITEM #{i}/#{part.items.size}"
          case part.direction
          when 1 then #vertical
            pos = pos.add(h)
            y = basey.add(pos)
            width.max(w)
          when 2 then #horizontal
            pos = pos.add(w)
            x = basex.add(pos)
            height.max(h)
          when 3 then #graph
            # compute the default positions!!            
            pos = pos.add(w).add(10)
            otherpos = otherpos.add(h).add(10)
            x = basex.add(pos)
            y = basey.add(otherpos)
            width.max(x.add(w))
            height.max(y.add(h))
          when 5 then #pages
            x = basex.add(0)
			      y = basey.add(0)
            width.max(w)
            height.max(h)
          end
        end
      end
      case part.direction
      when 1 then #vertical
        height.max(pos)
      when 2 then #horizontal
        width.max(pos)
      end
    end  
    
    def constrainShape(part, x, y, width, height)
      case part.kind 
      when "box"
        a = @cs.var("box1", 0)
        b = @cs.var("box2", 0)
      when "oval"
        a = @cs.var("pos1", 0)
        b = @cs.var("pos2", 0)
      when "rounded"
        a = @cs.var("rnd1", 20)
        b = @cs.var("rnd2", 20)
      end
      margin = @context.lineWidth_
      a = a.add(margin)
      b = b.add(margin)
      info = constrain(part.content, x.add(a), y.add(b))
      ow = info[0]
      oh = info[1]
      # position of sub-object depends on size of sub-object, so we
      # have to be careful about the circular dependencies
      if part.kind == "oval"
        sq2 = 2 * Math.sqrt(2.0)
        a.max(ow.div(sq2))
        b.max(oh.div(sq2))
        a.max(b)
      end
      width.max(ow.add(a.mul(2)))
      height.max(oh.add(b.mul(2)))
    end
  
    def constrainText(part, x, y, width, height)
      info = @context.measureText(part.string)
      #puts "MEASURE #{part.string} #{info.width_} #{context.font_}"
      width.max(info.width_ + 2)
      #width.max(info.width_ + 2)
      height.max(15)  # doesn't include height!
    end
  
    def constrainConnector(part)
      part.ends.each do |ce|
        to = boundary(ce.to)
        dynamic = ce.attach.dynamic_update
        x = to.x.add(to.w.mul(dynamic.x))
        y = to.y.add(to.h.mul(dynamic.y))
        @positions[ce._id] = EnsoPoint.new(x, y)
        constrainConnectorEnd(ce, x, y)
      end
    end
    
    def constrainConnectorEnd(e, x, y)
      constrain(e.label, x, y) if e.label
    end
    
    def boundary(shape)
      @positions[shape._id]
    end

    def boundary_fixed(shape)
      r = boundary(shape)
      EnsoRect.new(r.x.value, r.y.value, r.w.value, r.h.value) if !r.nil?
    end
  
    def position(shape)
      @positions[shape._id]
    end
    
    def position_fixed(shape)
      p = position(shape)
      EnsoPoint.new(p.x.value, p.y.value) if !p.nil?
    end
    
    def set_position(shape, x, y)
      r = boundary(shape)
      r.x.value = x
      r.y.value = y
    end
    
    def between(a, b, c)
       (a - @DIST <= b && b <= c + @DIST) || (c - @DIST <= b && b <= a + @DIST)
    end
    
    def rect_contains(rect, pnt)
      rect.x <= pnt.x && pnt.x <= rect.x + rect.w  && rect.y <= pnt.y && pnt.y <= rect.y + rect.h
    end
    
    # compute distance of pnt from line
    def dist_line(p0, p1, p2)
      num = (p2.x - p1.x) * (p1.y - p0.y) - (p1.x - p0.x) * (p2.y - p1.y)
      den = (p2.x - p1.x) ** 2 + (p2.y - p1.y) ** 2
      num.abs() / Math.sqrt(den)
    end
    # ----- drawing --------    
    
    def clear_refresh      
      @context.fillStyle_ = "white"
      @context.fillRect(0, 0, 5000, 5000)
      @context.fillStyle_ = "black"
      draw(@root, 0)
      @selection.do_paint if @selection
    end
    
    def draw(part, n)
      @context.font_ = "13px sans-serif"
      @context.strokeStyle_ = "#000000"
      @context.textBaseline_ = "top"

      with_styles(part) do
        #puts "#{' '.repeat(n)}DRAW  #{part}"
        send(("draw" + part.schema_class.name).to_sym, part, n+1)
      end
    end
  
    def drawContainer(part, n)
      if part.direction == 5
        # its pages
        current = if part.curent.nil? then 0 else part.current end
        draw(part.items[current], n+1)
      else
	      len = part.items.size - 1
	      start = 0
	      start.upto(len) do |i|
	        draw(part.items[i], n+1)
	      end
	    end
    end  
    
    def drawPage(shape, n)
      r = boundary_fixed(shape)
      @context.save
      @context.beginPath
      @context.fillStyle_ = "black"
      @context.fillText(shape.name, r.x + 2, r.y, 1000)
      @context.fill
      @context.restore
      draw(shape.content, n+1)
    end
    
    def drawGrid(grid, n)
      
    
    end
    
    
    def drawShape(shape, n)
      r = boundary_fixed(shape)
      if r
        margin = @context.lineWidth_
        m2 = margin - (margin % 2)
        case shape.kind
        when "box"
          #@context.fillRect(r.x, r.y, r.w, r.h)
          
          @context.save
          @context.rect(r.x + margin / 2, r.y + margin / 2, r.w - m2, r.h - m2)
          @context.fillStyle_ = 'Cornsilk'
          @context.shadowColor_ = '#999'
          @context.shadowBlur_ = 6
          @context.shadowOffsetX_ = 2
          @context.shadowOffsetY_ = 2
          @context.fill
          @context.stroke
          @context.restore
          
          # @context.strokeRect(r.x + margin / 2, r.y + margin / 2, r.w - m2, r.h - m2)
        when "oval"
          rx            = r.w / 2        # The X radius
          ry            = r.h / 2        # The Y radius
          x             = r.x + rx        # The X coordinate
          y             = r.y + ry        # The Y cooordinate
          rotation      = 0          # The rotation of the ellipse (in radians)
          start         = 0          # The start angle (in radians)
          finish        = 2 * Math.PI_ # The end angle (in radians)
          anticlockwise = false      # Whether the ellipse is drawn in a clockwise direction or
                                          # anti-clockwise direction
          @context.save
          @context.fillStyle_ = 'Cornsilk'
          @context.shadowColor_ = '#999'
          @context.shadowBlur_ = 6
          @context.shadowOffsetX_ = 2
          @context.shadowOffsetY_ = 2

          @context.beginPath
          @context.ellipse(x, y, rx, ry, rotation, start, finish, anticlockwise)
          @context.fill
          #@context.stroke
          @context.restore
        end
      end
      draw(shape.content, n+1)
    end
    
    def drawConnector(part, n)
      e0 = part.ends[0]
      e1 = part.ends[1]
      rFrom = boundary_fixed(e0.to)
      rTo = boundary_fixed(e1.to)
  
      case e0.to.kind 
      when "box", "rounded"
        pFrom = EnsoPoint.new(rFrom.x + rFrom.w * e0.attach.x, rFrom.y + rFrom.h * e0.attach.y)
      when "oval"
        thetaFrom = -Math.atan2(e0.attach.y - 0.5, e0.attach.x - 0.5)
        pFrom = EnsoPoint.new(rFrom.x + rFrom.w * (0.5 + Math.cos(thetaFrom) / 2), rFrom.y + rFrom.h * (0.5 - Math.sin(thetaFrom) / 2))
      end
      case e1.to.kind 
      when "box", "rounded"
        pTo = EnsoPoint.new(rTo.x + rTo.w * e1.attach.x, rTo.y + rTo.h * e1.attach.y)
      when "oval"
        thetaTo = -Math.atan2(e1.attach.y - 0.5, e1.attach.x - 0.5)
        pTo = EnsoPoint.new(rTo.x + rTo.w * (0.5 + Math.cos(thetaTo) / 2), rTo.y + rTo.h * (0.5 - Math.sin(thetaTo) / 2))
      end
    
      sideFrom = getSide(e0.attach)
      sideTo = getSide(e1.attach)
      # to and from are different      
      if sideFrom == sideTo   # this it the "same" case
        ps = simpleSameSide(pFrom, pTo, sideFrom)
      elsif (sideFrom - sideTo).abs % 2 == 0  # this is the "opposite" case
        ps = simpleOppositeSide(pFrom, pTo, sideFrom)
      else  # this is the "orthogonal" case
        if e0.to == e1.to
          ps = sameObjectCorner(pFrom, pTo, sideFrom)
        else
          ps = simpleOrthogonalSide(pFrom, pTo, sideFrom)
        end
      end
            
      ps.unshift(pFrom)
      ps << pTo
  
      part.path.clear
      ps.each {|p| part.path << @factory.Point(p.x, p.y) }

      @context.save
      @context.beginPath
      ps.map { |p| 
        @context.lineTo(p.x, p.y)
      }
      @context.stroke
  
      drawEnd e0, e1, pFrom, pTo
      drawEnd e1, e0, pTo, pFrom
      @context.restore
    end
  
    def drawEnd(cend, other_end, r, s)
      side = getSide(cend.attach)
      
      # draw the labels
      rFrom = boundary_fixed(cend.to)
      rTo = boundary_fixed(other_end.to)

      case side
      when 0 # UP
        angle = 90
        align = 'left'
        offsetX = 1
        if s.x < r.x  # going left
          offsetY = 0
        else
          offsetY = -1
        end
      when 1 # RIGHT
        angle = 0
        align = 'left'
        offsetX = 1
        if s.y < r.y  # going up
          offsetY = 0
        else
          offsetY = -1
        end
      when 2 # DOWN
        angle = -90
        align = 'left'
        offsetX = 1
        if r.x < s.x  # going right
          offsetY = 0
        else
          offsetY = -1
        end
      when 3 # LEFT
        angle = 0
        align = 'right'
        offsetX = -1
        if s.y < r.y  # going up
          offsetY = 0
        else
          offsetY = -1
        end
      end
      with_styles(cend.label) do 
        @context.save
        @context.translate(r.x, r.y)
        @context.rotate(-Math.PI_ * angle / 180)
        
        @context.textAlign_ = align
        textHeight = 16
        @context.fillText(cend.label.string, offsetX * 3, offsetY * textHeight) 
        
        @context.restore
      end
  
      # draw the arrows
      if cend.arrow == ">" || cend.arrow == "<"
        @context.save
        size = 5
        angle = -Math::PI * (1 - side) / 2
        @context.beginPath
        index = 0
        #puts "ARROW #{arrow}"
        rFrom = boundary_fixed(cend.to)      
        
        arrow = [ EnsoPoint.new(0,0), EnsoPoint.new(2,1), EnsoPoint.new(2,-1), EnsoPoint.new(0,0) ].each do |p|
          px = Math.cos(angle) * p.x - Math.sin(angle) * p.y
          py = Math.sin(angle) * p.x + Math.cos(angle) * p.y
          px = (px * size  + r.x) 
          py = (py * size + r.y)
          if index == 0
            @context.moveTo(px, py)
          else
            @context.lineTo(px, py)
          end
          index = index + 1
        end
        @context.closePath
        @context.fill
        @context.restore
      end
    end
  
    def simpleSameSide(a, b, d)
      case d # side from
      when 0 # UP
        z = System.min(a.y - @defaultConnectorDist, b.y - @defaultConnectorDist)
        [EnsoPoint.new(a.x, z), EnsoPoint.new(b.x, z)]
      when 1 # RIGHT
        z = System.max(a.x + @defaultConnectorDist, b.x + @defaultConnectorDist)
        [EnsoPoint.new(z, a.y), EnsoPoint.new(z, b.y)]
      when 2 # DOWN
        z = System.max(a.y + @defaultConnectorDist, b.y + @defaultConnectorDist)
        [EnsoPoint.new(a.x, z), EnsoPoint.new(b.x, z)]
      when 3 # LEFT
        z = System.min(a.x - @defaultConnectorDist, b.x - @defaultConnectorDist)
        [EnsoPoint.new(z, a.y), EnsoPoint.new(z, b.y)]
      end  
    end
  
    def simpleOppositeSide(a, b, d)
      case d
      when 0, 2 # UP, DOWN
        z = average(a.y, b.y)
        [EnsoPoint.new(a.x, z), EnsoPoint.new(b.x, z)]
      when 1, 3# LEFT, RIGHT
        z = average(a.x, b.x)
        [EnsoPoint.new(z, a.y), EnsoPoint.new(z, b.y)]
      end
    end
  
    def average(m, n)
      Integer((m + n) / 2)
    end
  
    def sameObjectCorner(a, b, d)
      case d
      when 0, 2  # UP, DOWN
        if d == 0
          z = a.y - @defaultConnectorDist
        else
          z = a.y + @defaultConnectorDist
        end
        if a.x > b.x  # up and left
          m = b.x - @defaultConnectorDist
        else
          m = b.x + @defaultConnectorDist
        end
        [EnsoPoint.new(a.x, z), EnsoPoint.new(m, z), EnsoPoint.new(m, b.y)]
      when 1, 3# LEFT, RIGHT
        if d == 1
          z = a.x - @defaultConnectorDist
        else
          z = a.x + @defaultConnectorDist
        end
        if a.y > b.y  # up and left
          m = b.y - @defaultConnectorDist
        else
          m = b.y + @defaultConnectorDist
        end
        [EnsoPoint.new(z, a.y), EnsoPoint.new(z, m), EnsoPoint.new(b.x, m)]
      end    
    end
    
    def simpleOrthogonalSide(a, b, d)
      case d
      when 0, 2 # UP, DOWN
        [EnsoPoint.new(a.x, b.y)]
      when 1, 3# LEFT, RIGHT
        [EnsoPoint.new(b.x, a.y)]
      end  
    end
  
    def drawText(text, n)
      r = boundary_fixed(text)
      @context.save
      @context.beginPath
      @context.fillStyle_ = "black"
      @context.fillText(text.string, r.x + 2, r.y, 1000)
      @context.fill
      @context.restore
    end
   
    #  --- helper functions ---
    def with_styles(part, &block)
      if !part.nil?
        if part.styles.size > 0
          @context.save
          part.styles.each do |style|
            if style.Pen?
              if style.width
                @context.lineWidth_ = style.width
              end
              if style.color
                @context.strokeStyle_ = makeColor(style.color)
              end
            elsif style.Font?
              @context.font_ = makeFont(style)
            elsif style.Brush?
              @context.fillStyle_ = makeColor(style.color)
            end
          end
          block.call
          @context.restore
        else
          block.call
        end
      end
    end
  
    def makeColor(c)
      "\##{to_byte(c.r)}#{to_byte(c.g)}#{to_byte(c.b)}"
    end
    
    def to_byte(v)
      v.to_hex.rjust(2, "0")
    end
    
    # "font-style font-variant font-weight font-size/line-height font-family"
    def makeFont(font)
      s = ""
      s = s + font.style + " " if !font.style.nil?
      s = s + font.weight + " " if !font.weight.nil?
      s = s + "#{font.size}px"
      s = s + " " + font.family if !font.family.nil?
      s
    end  
  end
  
  ############# selection #####
  class Selection
    def do_mouse_down(e)
    end

		def do_mouse_up
		end
		
		def do_move(e, down)    
    end
    
    def do_paint
    end
    
    def clear
    end
	end
	  
  class MoveShapeSelection < Selection
    def initialize(diagram, part, down)
      @diagram = diagram
      @part = part
      @down = down
      @move_base = @diagram.boundary_fixed(part)
    end
    
    def do_move(pnt, down)
      if down
        @diagram.set_position(@part, @move_base.x + (pnt.x - @down.x), @move_base.y + (pnt.y - @down.y))
        @diagram.clear_refresh
      end
    end
    
    def do_paint()
    end
  
    def to_s
      "MOVE_SEL #{@part}"
    end
  end
  
  class ConnectorSelection < Selection
    def initialize(diagram, conn)
      @diagram = diagram
      @conn = conn
      @ce = nil
    end
      
    def do_paint()
      @diagram.context.save
      @diagram.context.fillStyle_ = @diagram.makeColor(@diagram.factory.Color(255, 0, 0))
      size = 8
      p = @conn.path[0]
      @diagram.context.fillRect(p.x + (-size / 2), p.y + (-size / 2), size, size)
      p = @conn.path[-1]
      @diagram.context.fillRect(p.x + (-size / 2), p.y + (-size / 2), size, size)
      #@conn.path.each do |p|
      #end
      @diagram.context.restore
    end
      
    def do_mouse_down(pnt)
      size = 8
      pnt = @diagram.factory.Point(pnt.x, pnt.y)

      p = @conn.path[0]
      r = @diagram.factory.Rect(p.x - size / 2, p.y - size / 2, size, size)
      if @diagram.rect_contains(r, pnt)
        @ce = @conn.ends[0]
      else
        p = @conn.path[-1]
        r = @diagram.factory.Rect(p.x - size / 2, p.y - size / 2, size, size)
        if @diagram.rect_contains(r, pnt)
          @ce = @conn.ends[1]
        else
          @ce = nil
        end
      end
      @ce
    end

    def do_move(pnt, down)
      if down and @ce
        bounds = @diagram.boundary_fixed(@ce.to)
        x = pnt.x - (bounds.x + bounds.w / 2)
        y = pnt.y - (bounds.y + bounds.h / 2)
        if x == 0 && y == 0
          nil
        else
          #puts("FROM #{x} #{y}")
          angle = Math.atan2(y, x)
          nx = normalize(Math.cos(angle))
          ny = normalize(Math.sin(angle))
          #puts("   EDGE #{nx} #{ny}")
          @ce.attach.x = nx
          @ce.attach.y = ny
          # @diagram.set_position(@ce, bounds.x + @ce.attach.x * bounds.w, bounds.y + @ce.attach.y * bounds.h)
          @diagram.clear_refresh
          #puts("   EDGE #{@ce.attach.x} #{@ce.attach.y}")
        end
      end
    end
    
    def normalize(n)
      n = n * Math.sqrt(2)
      n = System.max(-1, n)
      n = System.min(1, n)
      n = (n + 1) / 2
      n
    end
    
		def do_mouse_up
      @ce = nil
    end
    
    def to_s
      "CONT_SEL #{@conn}"
    end
  end
  
  class PointSelection < Selection
    def initialize(diagram, ce, lastSelection)
      @diagram = diagram
      @ce = ce
      @lastSelection = lastSelection
    end
    
    
    def to_s
      "PNT_SEL #{@ce}   #{@lastSelection}ss"
    end
  end
  
    
  ############# low level geometry #####
  
  class EnsoPoint
    def initialize(x, y)
      @x = x
      @y = y
    end
    attr_accessor :x, :y
  end
  
  class EnsoRect
    def initialize(x, y, w, h)
      @x = x
      @y = y
      @w = w
      @h = h
    end
    attr_accessor :x, :y, :w, :h  
  end
  

      
end