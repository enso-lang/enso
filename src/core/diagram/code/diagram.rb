require 'wx'
include Wx

require 'core/diagram/code/base_window'
require 'core/diagram/code/constraints'

  # a path is specified by a constraint system
  #   the end is connected to a position on the part (h,w) 
  #       where (h==0 || h==1) || (w==0 || w==1)
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
  #  Within each case there are some subcases

def RunDiagramApp(content = nil)
  Wx::App.run do
    win = DiagramFrame.new
    win.set_root content if content
    win.show 
  end
end

class DiagramFrame < BaseWindow
  def initialize(title = 'Diagram')
    super(title)
    evt_paint :on_paint
    evt_left_dclick :on_double_click
    evt_left_down :on_mouse_down
    evt_motion :on_move
    evt_left_up :on_mouse_up

    @menu_id = 0
    @move_selection = nil
    @select_color = Wx::Colour.new(0, 255, 0)
  end
  
  attr_accessor :listener
  
  def on_open
    dialog = FileDialog.new(self, "Choose a file", "", "", "Diagrams (*.diagram;)|*.diagram;")
    if dialog.show_modal() == ID_OK
      path = dialog.get_path
      extension = File.extname(path)
      raise "File is not a diagram" if extension != "diagram"
      content = Load(dialog.get_path())
      set_root(content)
    end
  end
  
  def set_root(root)
    #puts "ROOT #{root.class}"
    @root = root
    clear_refresh
  end

  def clear_refresh
    refresh
    @cs = ConstraintSystem.new
    @positions = {}
  end      
  
  # ------- event handling -------  
  def on_double_click(e)
    @move_selection = nil
    @down_x = e.x
    @down_y = e.y
    move, edit = find(@root, e)
    #puts "FIND #{move}, #{edit}"
    if edit && edit.Text?
      @edit_selection = edit
      r = boundary(@edit_selection)
      n = 3
      #puts r.x, r.y, r.w, r.h
      extraWidth = 10
      @edit_control = Wx::TextCtrl.new(self, 0, "", 
        Point.new(r.x - n, r.y - n), Size.new(r.w + 2 * n + extraWidth, r.h + 2 * n),
        0)  # Wx::TE_MULTILINE
      
      style = Wx::TextAttr.new()
      style.set_text_colour(makeColor(@foreground))
      style.set_font(makeFont(@font))      
      @edit_control.set_default_style(style)
      
      @edit_control.append_text(@edit_selection.string)
      @edit_control.show
      @edit_control.set_focus
    end
  end

  def on_mouse_down(e)
    need_refresh = !@move_selection.nil?
    if @edit_control
      new_text = @edit_control.get_value()
      @edit_selection.string = new_text
      @listener.notify_change(@edit_selection, new_text) if @listener
      @edit_control.destroy
      need_refresh = true
      @edit_selection = nil
      @edit_control = nil
    end
    @move_selection = nil
    move, edit = find(@root, e)
    #puts "FIND #{move}, #{edit}"
    if move
      @down_x = e.x
      @down_y = e.y
      @move_selection = move
      @move_base = boundary(@move_selection)
    end    
    refresh if need_refresh
  end
  
  def on_mouse_up(e)
    @move_selection = false
  end

  def on_move(e)
    return unless @move_selection
    @positions[@move_selection].x.value = @move_base.x + (e.x - @down_x)
    @positions[@move_selection].y.value = @move_base.y + (e.y - @down_y)
    refresh
  end

  # ---- finding ------
  def find(part, pnt)
    if pat.Connector?
      part.path.each do {
        from = nil
        ps.each do |to|
          continue if from.nil?
          if between(from.x, pnt.x, to.x) && between(from.y, pnt.y, to.y)
            if near_line(pnt, from, to)
              
        end
    else
      b = boundary(part)
      return if b.nil?
      #puts "#{part}: #{b.x} #{b.y} #{b.w} #{b.h}"
      move, edit = nil, nil
      if rect_contains(b, pnt)
        if part.Container?
          part.items.each do |sub|
            move, edit = find(sub, pnt)
            move = sub if edit && part.direction == 3
            return move, edit if edit
          end
        elsif part.Shape?
          move, edit = find(part.content, pnt) if part.content
          edit = part if !edit
        elsif part.Text?
          edit = part
        end
      end
    end
    return move, edit
  end
  
  def rect_contains(rect, pnt)
    rect.x <= pnt.x && pnt.x <= rect.x + rect.w \
    && rect.y <= pnt.y && pnt.y <= rect.y + rect.h
  end
  
  # ----- constrain -----
  def get_var(name, constraint)
    if constraint && constraint.var
      var = @cs[constraint.var]
    else
      var = @cs.var(name)
    end    
    var >= constraint.min if constraint && constraint.min
    return var
  end
  
  def do_constraints
    constrain(@root, @cs.value(0), @cs.value(0)) 
  end
  
  def constrain(part, x, y)
    w, h = nil
    with_styles part do 
      if part.Connector?
        send(("constrain" + part.schema_class.name).to_sym, part)
      else
        w = get_var("#{part}_w", part.constraints && part.constraints.width)
        h = get_var("#{part}_h", part.constraints && part.constraints.height)
    
        send(("constrain" + part.schema_class.name).to_sym, part, x, y, w, h)
        @positions[part] = Rect.new(x, y, w, h)
      end
    end
    return w, h
  end

  def constrainContainer(part, basex, basey, width, height)
    pos = @cs.value(0)
    otherpos = @cs.value(0)
    x, y = basex + 0, basey + 0
    #puts "CONTAINER #{width.to_s}, #{height.to_s}"
    part.items.each_with_index do |item, i|
      w, h = constrain(item, x, y)
      next if w.nil?
      #puts "ITEM #{i}/#{part.items.length}"
      case part.direction
      when 1 then #vertical
        pos = pos + h
        y = basey + pos
        width >= w
      when 2 then #horizontal
        pos = pos + w
        x = basex + pos
        height >= h
      when 3 then #graph
        pos = pos + w
        otherpos = otherpos + h
        x = basex + pos
        y = basey + otherpos
      end
    end
    case part.direction
    when 1 then #vertical
      height >= pos
    when 2 then #horizontal
      width >= pos
    when 3 then #horizontal
      width >= pos
      height >= otherpos
    end
  end  
  
  def constrainShape(part, x, y, width, height)
    margin = @dc.get_pen.get_width
    ow, oh = constrain(part.content, x + margin, y + margin)
    width >= ow + (2 * margin)
    height >= oh + (2 * margin)
  end

  def constrainText(part, x, y, width, height)
    w, h = @dc.get_text_extent(part.string)
    width >= w
    height >= h
  end

  def constrainConnector(part)
    part.ends.each do |ce|
      to = @positions[ce.to]
      x = ( to.x + to.w * ce.attach.x ).round
      y = ( to.y + to.h * ce.attach.y ).round
      @positions[ce] = Pnt.new(x, y)
      constrainConnectorEnd(ce, x, y)
    end
  end
  
  def constrainConnectorEnd(e, x, y)
    constrain(e.label, x, y) if e.label
  end
  
  def boundary(shape)
    r = @positions[shape]
    return nil if r.nil?
    return Rect.new(r.x.value, r.y.value, r.w.value, r.h.value)
  end

  def position(shape)
    p = @positions[shape]
    return nil if p.nil?
    return Pnt.new(p.x.value, p.y.value)
  end
  
  
  # ----- drawing --------    
  # Writes the gruff graph to a file then reads it back to draw it
  def on_paint
    paint do | dc |
      @dc = dc
      @pen = @brush = @font = @foreground = nil
      do_constraints() if @positions == {}
      s = get_client_size()
      @pen = @brush = @font = @foreground = nil
      draw(@root)
    end
  end
  
  def draw(part)
    with_styles part do 
      send(("draw" + part.schema_class.name).to_sym, part)
    end
  end

  def drawContainer(part)
    (part.items.length-1).downto(0).each do |i|
      draw(part.items[i])
    end
  end  
  
  def drawShape(shape)
    r = boundary(shape)
    margin = @dc.get_pen.get_width
    m2 = margin - (margin % 2)
    @dc.draw_rectangle(r.x + margin / 2, r.y + margin / 2, r.w - m2, r.h - m2)
    draw(shape.content)
  end
  
  def drawConnector(part)
    drawEnd part.ends[0]
    drawEnd part.ends[1]
    
    pFrom = position(part.ends[0])
    pTo = position(part.ends[1])

    sideFrom = getSide(part.ends[0].attach)
    sideTo = getSide(part.ends[1].attach)
    if sideFrom == sideTo   # this it the "same" case
      ps = simpleSameSide(pFrom, pTo, sideFrom)
    elsif (sideFrom - sideTo).abs % 2 == 0  # this is the "opposite" case
      ps = simpleOppositeSide(pFrom, pTo, sideFrom)
    else  # this is the "orthogonal" case
      ps = simpleOrthogonalSide(pFrom, pTo, sideFrom)
    end
    
    ps.unshift(pFrom)
    ps << pTo
    
    part.path.clear
    ps.each do {|p| part.path << part.factory.Point(p.x, p.y) }
    @dc.draw_lines(ps.collect {|p| [p.x, p.y] })
  end

  def simpleSameSide(a, b, d)
    case d
    when 2 # DOWN
      z = [a.y + 10, b.y + 10].max
      return [Pnt.new(a.x, z), Pnt.new(b.x, z)]
    when 0 # UP
      z = [a.y - 10, b.y - 10].min
      return [Pnt.new(a.x, z), Pnt.new(b.x, z)]
    when 1 # RIGHT
      z = [a.x + 10, b.x + 10].max
      return [Pnt.new(z, a.y), Pnt.new(z, b.y)]
    when 3 # LEFT
      z = [a.x - 10, b.x - 10].min
      return [Pnt.new(z, a.y), Pnt.new(z, b.y)]
    end  
  end

  def simpleOppositeSide(a, b, d)
    case d
    when 0, 2 # UP, DOWN
      z = average(a.y, b.y)
      return [Pnt.new(a.x, z), Pnt.new(b.x, z)]
    when 1, 3# LEFT, RIGHT
      z = average(a.x, b.x)
      return [Pnt.new(z, a.y), Pnt.new(z, b.y)]
    end
  end

  def average(m, n)
    return Integer((m + n) / 2)
  end

  def simpleOrthogonalSide(a, b, d)
    case d
    when 0, 2 # UP, DOWN
      return [Pnt.new(a.x, b.y)]
    when 1, 3# LEFT, RIGHT
      return [Pnt.new(b.x, a.y)]
    end  
  end

  # sides are labeld top=0, right=1, bottom=2, left=3  
  def getSide(cend)
    return 0 if cend.y == 0 #top
    return 1 if cend.x == 1 #right
    return 2 if cend.y == 1 #bottom
    return 3 if cend.x == 0 #left
  end

  def drawEnd(cend)
    # todo: draw the arrow
    # position correctly!!
    draw(cend.label) if cend.label
  end

  def drawText(text)
    r = boundary(text)
    @dc.draw_text(text.string, r.x, r.y)
  end
 
  #  --- helper functions ---
  def with_styles(part)
    return if part.nil?
    oldPen = oldFont = oldBrush = oldForeground = nil
    part.styles.each do |style|
      if style.Pen?
        oldPen = @pen
        @dc.set_pen(makePen(@pen = style))
      elsif style.Font?
        oldFont = @font
        oldForeground = @foreground
        @dc.set_text_foreground(makeColor(@foreground = style.color))
        @dc.set_font(makeFont(@font = style))
      elsif style.Brush?
        oldBrush = @brush
        @dc.set_brush(makeBrush(@brush = style))
      end
    end
    if part == @move_selection
      oldPen = @pen
      @dc.set_pen(Wx::Pen.new(@select_color, @pen.width))
    end
    yield
    @dc.set_pen(makePen(@pen = oldPen)) if oldPen
    @dc.set_text_foreground(makeColor(@foreground = oldForeground)) if oldForeground
    @dc.set_font(makeFont(@font = oldFont)) if oldFont
    @dc.set_brush(makeBrush(@brush = oldBrush)) if oldBrush
  end

  def makeColor(c)
    return Wx::Colour.new(c.r, c.g, c.b)
  end

  def makePen(pen)
    return Wx::Pen.new(makeColor(pen.color), pen.width) # style!!!
  end
    
  def makeBrush(brush)
    return Wx::Brush.new(makeColor(brush.color))
  end

  def makeFont(font)
    weight = case
      when font.weight < 400 then Wx::FONTWEIGHT_LIGHT
      when font.weight > 400 then Wx::FONTWEIGHT_BOLD
      else Wx::FONTWEIGHT_NORMAL
      end
    style = case font.style
      when "italic" then Wx::FONTSTYLE_ITALIC
      when "slant" then Wx::FONTSTYLE_SLANT
      else FONTSTYLE_NORMAL
      end
    family = case font.name
      when "roman" then Wx::FONTFAMILY_ROMAN
      when "swiss" then Wx::FONTFAMILY_SWISS
      when "mono" then Wx::FONTFAMILY_MODERN
      when "teletype" then Wx::FONTFAMILY_TELETYPE
      else FONTFAMILY_DEFAULT
      end
    underline = false
    faceName = ""
    return Font.new(font.size, family, style, weight, underline, faceName)
  end
  
end

class Pnt
  def initialize(x, y)
    @x = x
    @y = y
  end
  attr_accessor :x, :y
end

class Rect
  def initialize(x, y, w, h)
    @x = x
    @y = y
    @w = w
    @h = h
  end
  attr_accessor :x, :y, :w, :h
end
