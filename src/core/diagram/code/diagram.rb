
require 'wx'
include Wx
require 'core/diagram/code/constraints'

def ViewDiagram(content)
  Wx::App.run { DiagramFrame.new(content).show }
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

class DiagramFrame < Wx::Frame
  def initialize(root)
    super(nil, :title => 'Diagram')
    evt_paint :on_paint
    evt_left_dclick :on_double_click
    evt_left_down :on_mouse_down
    evt_motion :on_move
    evt_left_up :on_mouse_up

    @down = false
    @move_selection = nil
    set_root(root)
  end

  def refresh
    super
    @cs = ConstraintSystem.new
    @positions = {}
  end
      
  def set_root(root)
    #puts "ROOT #{root.class}"
    @root = root
    refresh
  end

  
  # ------- event handling -------  
  def on_double_click(e)
    @move_selection = nil
    @down_x = e.x
    @down_y = e.y
    find(@root, e)
    if @edit_selection
      @down = false
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
      @edit_selection.string = @edit_control.get_value()
      @edit_control.destroy
      need_refresh = true
      @edit_selection = nil
      @edit_control = nil
    end
    @down = true
    @move_selection = nil
    @down_x = e.x
    @down_y = e.y
    find(@root, e)
    refresh if need_refresh
  end
  
  def on_mouse_up(e)
    @down = false
  end

  def on_move(e)
    return unless @move_selection && @down
    @positions[@move_selection].x.value += e.x - @down_x
    @positions[@move_selection].y.value += e.y - @down_y
    refresh
  end

  # ---- finding ------
  def find(part, pnt)
    catch :found do
      find1(part, pnt)
    end
  end
    
  def find1(part, pnt)
    if part.Container?
      part.items.each do |s|
        find1(s, pnt)
      end
    elsif part.Shape?
      if rect_contains(boundary(part), pnt)
        find1(part.content, pnt) if part.content
        @move_selection = part # largest enclosing part
      end
    elsif part.Text?
      @edit_selection = part
    end
  end
  
  def rect_contains(rect, pnt)
    rect.x <= pnt.x && pnt.x <= rect.x + rect.w \
    && rect.y <= pnt.y && pnt.y <= rect.y + rect.h
  end
  
  # ----- constrain -----
  def get_var(constraint)
    if constraint && constraint.var
      var = @cs[constraint.var]
    else
      var = @cs.new
    end    
    var >= constraint.min if constraint && constraint.min
    return var
  end
  
  def constrainPart(part, x, y)
    return if part.nil?
    w = get_var(part.constraints && part.constraints.width)
    h = get_var(part.constraints && part.constraints.height)
    
    with_styles part do
      if part.Container?
        constrainContainer(part, x, y, w, h)
      elsif part.Shape?
        constrainShape(part, x, y, w, h)
      elsif part.Text?
        constrainText(part, x, y, w, h)
      else
        raise "unknown shape"
      end
    end
    @positions[part] = Rect.new(x, y, w, h)
    return w, h
  end

  def constrainContainer(part, basex, basey, width, height)
    pos = @cs.value(0)
    x, y = basex, basey
    #puts "CONTAINER #{width.to_s}, #{height.to_s}"
    part.items.each_with_index do |item, i|
      w, h = constrainPart(item, x, y)
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
      end
    end
    case part.direction
    when 1 then #vertical
      height >= pos
    when 2 then #horizontal
      width >= pos
    end
  end  
  
  def constrainShape(part, x, y, width, height)
    margin = @dc.get_pen.get_width
    ow, oh = constrainPart(part.content, x + margin, y + margin)
    width >= ow + (2 * margin)
    height >= oh + (2 * margin)
  end

  def constrainText(part, x, y, width, height)
    w, h = @dc.get_text_extent(part.string)
    width >= w
    height >= h
  end

  def constrainGraph(part, x, y, width, height)
    part.items.each do |item|
      ow, oh = constrainPart(item.content, cs.value(item.location.x), cs.value(item.location.y))
      width >= base.x + ow
      height >= base.y + oh
    end
  end  

  def boundary(shape)
    r = @positions[shape]
    return Rect.new(r.x.value, r.y.value, r.w.value, r.h.value)
  end
  
  
  # ----- drawing --------    
  # Writes the gruff graph to a file then reads it back to draw it
  def on_paint
    paint do | dc |
      @dc = dc
      constrainPart(@root,@cs.value(0), @cs.value(0)) if @positions == {}
      s = get_client_size()
      drawPart(@root)
    end
  end
      
  def drawPart(part)
    with_styles part do
      if part.Container?
        (part.items.length-1).downto(0).each do |i|
          drawPart(part.items[i])
        end
      elsif part.Shape?
        drawShape(part)
      elsif part.Text?
        drawText(part)
      else
        raise "unknown shape"
      end
    end
  end
  
  def drawShape(shape)
    r = boundary(shape)
    margin = @dc.get_pen.get_width
    m2 = margin - (margin % 2)
    @dc.draw_rectangle(r.x + margin / 2, r.y + margin / 2, r.w - m2, r.h - m2)
    drawPart(shape.content)
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
        oldPen = @dc.get_pen unless oldPen
        @dc.set_pen(Pen(style))
      elsif style.Font?
        oldFont = @dc.get_font unless oldFont
        oldForeground = @dc.get_text_foreground unless oldForeground
        @dc.set_text_foreground(Color(style.color))
        @dc.set_font(Font(style))
      elsif style.Brush?
        oldBrush = @dc.get_brush unless oldBrush
        @dc.set_brush(Brush(style))
      end
    end
    yield
    @dc.set_pen(oldPen) if oldPen
    @dc.set_text_foreground(oldForeground) if oldForeground
    @dc.set_font(oldFont) if oldFont
    @dc.set_brush(oldBrush) if oldBrush
  end

  def Color(c)
    return Wx::Colour.new(c.r, c.g, c.b)
  end

  def Pen(pen)
    return Wx::Pen.new(Color(pen.color), pen.width) # style!!!
  end
    
  def Brush(brush)
    return Wx::Brush.new(Color(brush.color))
  end

  def Font(font)
    weight = font.bold ? Wx::FONTWEIGHT_BOLD : Wx::FONTWEIGHT_NORMAL
    style = font.italic ? Wx::FONTSTYLE_ITALIC : Wx::FONTSTYLE_NORMAL
    return Font.new(font.size, Wx::FONTFAMILY_MODERN, style, weight)
  end
  
end

