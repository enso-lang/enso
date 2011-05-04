
require 'grammar/cpsparser'
require 'grammar/grammargrammar'
require 'tools/print'

require 'wx'
include Wx

class DiagramFrame < Wx::Frame
   def initialize(part, factory)
     super(nil, :title => 'Diagram')
     evt_paint :on_paint
     evt_left_dclick :on_double_click
     evt_left_down :on_mouse_down
     evt_motion :on_move
     evt_left_up :on_mouse_up
     @part = part
     @factory = factory

     @down = false
     @move_selection = nil
   end

  def on_double_click(e)
     @move_selection = nil
     @down_x = e.x
     @down_y = e.y
     find(@part, e)
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
     find(@part, e)
   end
   
   def on_mouse_up(e)
     @down = false
   end

   def on_move(e)
     return unless @move_selection && @down
     @move_selection.boundary.x += e.x - @down_x
     @move_selection.boundary.y += e.y - @down_y
     @down_x = e.x
     @down_y = e.y
     refresh()
   end

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
     
   # Writes the gruff graph to a file then reads it back to draw it
   def on_paint
     paint do | dc |
        s = get_client_size()
        r = @factory.Rect(0, 0, s.get_width(), s.get_height())
        drawPart(dc, @part, r)
     end
   end
   
   def Color(c)
     Wx::Colour.new(c.r, c.g, c.b)
   end

   def LineFormat(lf)
     Wx::Pen.new(Color(lf.color), lf.width) # style!!!
   end
      
   def ShapeFormat(dc, sf)
      dc.set_pen(LineFormat(sf.line))
      dc.set_brush(Wx::Brush.new(Color(sf.fill_color)))
   end

   def drawPart(dc, part, rect)
     return if part.nil?
     if part.Shape?
       drawShape(dc, part, rect)
     elsif part.Text?
       drawText(dc, part, rect)
     else
       (part.items.length-1).downto(0).each do |i|
         drawPart(dc, part.items[i], rect)
       end
     end
   end
   
   def drawShape(dc, shape, rect)
     ShapeFormat(dc, shape.format)
     r = shape.boundary
     dc.draw_rectangle(r.x, r.y, r.w, r.h)
     w = shape.format.line.width
     sub_rect = @factory.Rect(r.x + w, r.y + w, r.w - 2 * w, r.h - 2 * w) 
     drawPart(dc, shape.content, sub_rect)
   end

   def drawText(dc, text, rect)
     weight = text.bold ? Wx::FONTWEIGHT_BOLD : Wx::FONTWEIGHT_NORMAL
     style = text.italic ? Wx::FONTSTYLE_ITALIC : Wx::FONTSTYLE_NORMAL
     font = Font.new(text.size, Wx::FONTFAMILY_MODERN, style, weight)
     text.boundary = rect
     dc.set_text_foreground(Color(text.color))
     dc.set_font(font)
     dc.draw_text(text.string, rect.x, rect.y)
   end
   
end

grammar_grammar = GrammarGrammar.grammar
schema_grammar = CPSParser.load('schema/schema.grammar', grammar_grammar, GrammarSchema.schema)

diagram_schema = CPSParser.load('applications/diagramedit/diagram.schema', schema_grammar, SchemaSchema.schema)

f = Factory.new(diagram_schema)

red = f.Color(255, 0, 0)
blue = f.Color(0, 0, 255)
black = f.Color(0, 0, 0)
white = f.Color(255, 255, 255)
t1 = f.Text(nil, "Hello World", "Helvetica", 18, true, true, red)
t2 = f.Text(nil, "Enso!", "Helvetica", 18, false, false, black)
s1 = f.Shape(f.Rect(10, 10, 100, 100), f.ShapeFormat(f.LineFormat(5, "", red), white), t2)
s2 = f.Shape(f.Rect(20, 20, 200, 100), f.ShapeFormat(f.LineFormat(10, "", blue), white), t1)
content = f.Container(nil, 1, [s1, s2])

Print.print(content)

Wx::App.run { DiagramFrame.new(content, f).show }

