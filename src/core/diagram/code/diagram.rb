
require 'wx'
include Wx

def ViewDiagram(content, f)
  Wx::App.run { DiagramFrame.new(content, f).show }
end

class DiagramFrame < Wx::Frame
  def initialize(root, factory)
    super(nil, :title => 'Diagram')
    evt_paint :on_paint
    evt_left_dclick :on_double_click
    evt_left_down :on_mouse_down
    evt_motion :on_move
    evt_left_up :on_mouse_up
    @factory = factory

    @down = false
    @move_selection = nil
    set_root(root)
  end

  def set_root(root)
   @root = root
   s = get_client_size()
   rect = @factory.Rect(0, 0, s.get_width(), s.get_height())
   layoutPart(@root, rect)
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
     r = @edit_selection.boundary
     n = 5
     rx = Wx::Rect.new(r.x - n, r.y - n, r.w + 2 * n, r.h + 2 * n)
     @edit_control.set_size(rx)
     #@edit_control.set_style(Wx::TE_MULTILINE)
     @edit_control.set_value(@edit_selection.string)
     @edit_control.show
     @edit_control.set_focus
    end
  end

  def on_mouse_down(e)
    if @edit_control
     @edit_selection.string = @edit_control.get_value()
     @edit_control.destroy
     refresh
     @edit_selection = nil
     @edit_control = nil
    end
    @down = true
    @move_selection = nil
    @down_x = e.x
    @down_y = e.y
    find(@root, e)
  end
  
  def on_mouse_up(e)
    @down = false
  end

  def on_move(e)
    return unless @move_selection && @down
    @move_selection.boundary.x += e.x - @down_x
    @move_selection.boundary.y += e.y - @down_y
    layoutPart(@move_selection, 
    @down_x = e.x
    @down_y = e.y
    refresh()
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
      if rect_contains(part.boundary, pnt)
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
  
  # ----- layout -----
  def layoutPart(part, rect)
    return if part.nil?
    if part.Container?
      (part.items.length-1).downto(0).each do |i|
        layoutPart(part.items[i], rect)
      end
    elsif part.Shape?
      layoutShape(part, rect)
    elsif part.Text?
      layoutText(part, rect)
    else
      raise "unknown shape"
    end
  end
  
  def layoutShape(shape, rect)
    if shape.boundary
      rect = shape.boundary
    else
      shape.boundary = rect
    end
    w = 3 # shape.format.line.width
    sub_rect = @factory.Rect(rect.x + w, rect.y + w, rect.w - 2 * w, rect.h - 2 * w) 
    layoutPart(shape.content, sub_rect)
  end

  def layoutText(text, rect)
    text.boundary = rect
  end
  
  # ----- min -----
  def constrainPart(part)
    return f.Size if part.nil?
    if part.Container?
      constrainContainer(part)
    elsif part.Shape?
      constrainShape(part, rect)
    elsif part.Text?
      constrainText(part, rect)
    else
      raise "unknown shape"
    end
  end

  def constrainContainer(part)
    result = f.Size
    constraint: constraint.width.min < this.width  if constraint.width.min 
    constraint: constraint.height.min < this.height  if constraint.height.min 
    constraint: constraint.width.var == this.width  if constraint.width.var 
    constraint: constraint.height.var == this.height  if constraint.height.var 
    (part.items.length-1).downto(0).each do |i|
      item = part.items[i]
      constrainPart(item, rect)
      case part.direction
      when "graph" then
        constraint: item.x = this.x + item.pos.x
        constraint: item.y = this.y + item.pos.y
        constraint: item.width + item.pos.x < this.width
        constraint: item.height + item.pos.y < this.height
      when "vertical" then
        fooVar = this.y unless fooVar
        constraint: item.x = item.pos.x
        constraint: item.y = fooVar
        constraint: item.width < this.width
        constraint: fooVar + item.height < fooVar'
      when "horizontal" then
        fooVar = this.x unless fooVar
        constraint: item.x = fooVar
        constraint: item.y = item.pos.y
        constraint: fooVar + item.width < fooVar'
        constraint: item.height < this.height
      end
    end
  end  
  
  def constrainPart(shape, rect)
    w = 3 # shape.format.line.width
    content.x < this.x + w
    content.y < this.y + w
    content.width + 2*w < this.width
    content.height + 2*w < this.height
  end

  def constrainText(text, rect)
    w, h = @dc.get_text_extent(text.string
    constraint: w < this.width
    constraint: h < this.height
  end
  
  # ----- drawing --------    
  # Writes the gruff graph to a file then reads it back to draw it
  def on_paint
    paint do | dc |
      s = get_client_size()
      drawPart(dc, @root)
    end
  end
      
  def drawPart(dc, part)
    return if part.nil?
    oldPen = oldFont = oldBrush = oldForeground = nil
    part.styles.each do |style|
      if style.Pen?
        oldPen = dc.get_pen unless oldPen
      dc.set_pen(Pen(style))
    elsif style.Font?
      oldFont = dc.get_font unless oldFont
      oldForeground = dc.get_text_foreground unless oldForeground
      dc.set_text_foreground(Color(style.color))
      dc.set_font(Font(style))
    elsif style.Brush?
      oldBrush = dc.get_brush unless oldBrush
      dc.set_brush(Brush(style))
     end
    end
    if part.Container?
      (part.items.length-1).downto(0).each do |i|
        drawPart(dc, part.items[i])
      end
    elsif part.Shape?
      drawShape(dc, part)
    elsif part.Text?
      drawText(dc, part)
    else
      raise "unknown shape"
    end

    dc.set_pen(oldPen) if oldPen
    dc.set_text_foreground(oldForeground) if oldForeground
    dc.set_font(oldFont) if oldFont
    dc.set_brush(oldBrush) if oldBrush
  end
  
  def drawShape(dc, shape)
    r = shape.boundary
    dc.draw_rectangle(r.x, r.y, r.w, r.h)
    w = 3 # shape.format.line.width
    drawPart(dc, shape.content)
  end

  def drawText(dc, text)
    dc.draw_text(text.string, text.boundary.x, text.boundary.y)
  end
 
  #  --- helper functions ---
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

