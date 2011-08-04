require 'wx'
include Wx

require 'core/diagram/code/base_window'
require 'core/diagram/code/constraints'

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
      @edit_control = Wx::TextCtrl.new(self, 0)
      r = boundary(@edit_selection)
      n = 0
      #puts r.x, r.y, r.w, r.h
      @edit_control.set_dimensions(r.x - n, r.y - n, r.w + 2 * n, r.h + 2 * n)
      #@edit_control.set_style(Wx::TE_MULTILINE)
      @edit_control.set_value(@edit_selection.string)
      @edit_control.show
      @edit_control.set_focus
    end
  end

  def on_mouse_down(e)
    need_refresh = false
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
    #puts "#{part.ends[0].to}"
    #puts "POS #{@positions.keys}"
    from = @positions[part.ends[0].to]
    to = @positions[part.ends[1].to]
    start_x = from.x + (from.w / 2)
    start_y = from.y + from.h
    end_x = to.x
    end_y = to.y + (to.h / 2)
    mid_x = start_x
    mid_y = end_y
    @positions[part.path[0]] = Pnt.new(start_x, start_y)
    @positions[part.path[1]] = Pnt.new(mid_x, mid_y)
    @positions[part.path[2]] = Pnt.new(end_x, end_y)
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
      @pen = @brush = @font = nil
      do_constraints() if @positions == {}
      s = get_client_size()
      @pen = @brush = @font = nil
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
    p1 = position(part.path[0])
    p2 = position(part.path[1])
    p3 = position(part.path[2])
    coords = [[p1.x, p1.y], [p2.x, p2.y], [p3.x, p3.y]]
    #puts "#{coords}"
    @dc.draw_lines(coords)
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
        oldForeground = @dc.get_text_foreground unless oldForeground
        @dc.set_text_foreground(makeColor(style.color))
        @dc.set_font(makeFont(@font = style))
      elsif style.Brush?
        oldBrush = @brush
        @dc.set_brush(makeBrush(@brush = style))
      end
    end
    yield
    @dc.set_pen(makePen(oldPen)) if oldPen
    @dc.set_text_foreground(oldForeground) if oldForeground
    @dc.set_font(makeFont(oldFont)) if oldFont
    @dc.set_brush(makeBrush(oldBrush)) if oldBrush
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