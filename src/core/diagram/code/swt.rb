require 'java'

module GUI
  class << self
    attr_accessor :display
  end
  
  class Application
    GUI::display = org.eclipse.swt.widgets.Display.new
    
    def self.run
      @@app = Application.new
      yield
      # Classic SWT stuff
      while (!GUI::display.is_disposed) do
        GUI::display.sleep unless GUI::display.read_and_dispatch
      end
      GUI::display.dispose
    end
  end
  
  class Window    

    def initialize(name = "New Window")
      @window = org.eclipse.swt.widgets.Shell.new(GUI::display)
      @window.setSize(800, 600)
      @window.setText(name)
    end

    def get_client_size
      p = @window.getClientArea()
      return p.width, p.height
    end

    #include org.eclipse.swt.events.ArmListener
    #def widgetArmed(armEvent); end

    include org.eclipse.swt.events.ControlListener

    def control_moved(controlEvent); end
    def control_resized(controlEvent); end

    #include org.eclipse.swt.events.DisposeListener
    def widget_disposed(disposeEvent); end

    #include org.eclipse.swt.events.DragDetectListener
    def drag_detected(dragDetectEvent); end

    #include org.eclipse.swt.events.ExpandListener
    def item_collapsed(expandEvent); end
    def item_expanded(expandEvent); end

    #include org.eclipse.swt.events.FocusListener
    def focus_gained(focusEvent); end
    def focus_lost(focusEvent); end

    #include org.eclipse.swt.events.GestureListener
    def gesture(gestureEvent); end

    #include org.eclipse.swt.events.HelpListener
    def help_requested(helpEvent); end

    include org.eclipse.swt.events.KeyListener
    def key_pressed(keyEvent); end
    def key_released(keyEvent); end
    
    #include org.eclipse.swt.events.MenuListener
    #include org.eclipse.swt.events.MenuDetectListener
    #def menu_detected (menuDetectEvent); end

    #include org.eclipse.swt.events.MenuListener
    #def menu_hidden(menuEvent); end
    #def menu_shown(menuEvent); end

    #include org.eclipse.swt.events.ModifyListener
    #def modify_text(modifyEvent); end

    include org.eclipse.swt.events.MouseListener
    def mouse_double_click(mouseEvent); end
    def mouse_down(mouseEvent); end
    def mouse_up(mouseEvent); end

    include org.eclipse.swt.events.MouseMoveListener
    def mouse_move(mouseEvent); end

    include org.eclipse.swt.events.MouseTrackListener
    def mouse_enter(mouseEvent); end
    def mouse_exit(mouseEvent); end
    def mouse_hover(mouseEvent); end

    #include org.eclipse.swt.events.MouseWheelListener
    # def mouse_scrolled(mouseEvent); end 

#    include org.eclipse.swt.events.PaintListener
#    def paint_control(paintEvent); end

    #include org.eclipse.swt.events.SegmentListener
    # def widget_selected(selectionEvent); end

    #include org.eclipse.swt.events.SelectionListener
    # def widget_default_selected(selectionEvent); end

    #include org.eclipse.swt.events.ShellListener
    # def shell_activated(shellEvent); end
    # def shell_closed(shellEvent); end
    # def shell_deactivated(shellEvent); end
    # def shell_deiconified(shellEvent); end
    # def shell_iconified(shellEvent); end

    #include org.eclipse.swt.events.TouchListener
    def touch(touchEvent); end

    #include org.eclipse.swt.events.TraverseListener
    # def key_traversed(traverseEvent); end

    #include org.eclipse.swt.events.VerifyListener
    # def verify_text(verifyEvent); end

    #include org.eclipse.swt.events.TreeListener
    # def tree_collapsed(treeEvent); end
    # def tree_expanded(treeEvent); end

    def show
      # @window.addArmListener(self)
      @window.addControlListener(self)
      # @window.addDisposeListener(self)
      # @window.addDragDetectListener(self)
      # @window.addExpandListener(self)
      # @window.addFocusListener(self)
      # @window.addGestureListener(self)
      # @window.addHelpListener(self)
      @window.addKeyListener(self)
      # @window.addMenuDetectListener(self)
      # @window.addMenuListener(self)
      # @window.addModifyListener(self)
      @window.addMouseListener(self)
      @window.addMouseMoveListener(self)
      # @window.addMouseTrackListener(self)
      # @window.addMouseWheelListener(self)
      @window.addPaintListener do |e|
        self.on_paint(Graphics.new(e.gc), Rect.new(e.x, e.y, e.width, e.height), e.count)
      end
      # @window.addSegmentListener(self)
      # @window.addSelectionListener(self)
      # @window.addShellListener(self)
      # @window.addTouchListener(self)
      # @window.TraverseListener(self)
      # @window.TreeListener(self)
      # @window.VerifyListener(self)
      @window.open
    end
    
    def redraw; @window.redraw; end
  end    
  
  class Graphics
    def initialize(gc)
      @gc = gc
      @stroke_color = Color.new(0, 0, 0)
      @stroke_width = 1
      @fill_color = Color.new(255, 255, 255)
      p "STROKE #{stroke_width}"
    end

    def make_color(c)
      org.eclipse.swt.graphics.Color.new(GUI::display, c.r, c.g, c.b)
    end
    
   # attr_reader :stroke_color
    def stroke_color
      puts "STROKE COLOR #{@stroke_color}"
      @stroke_color
    end
    def stroke_color=(c)
      @stroke_color = c
      @gc.set_foreground(make_color(c))
    end

    attr_reader :stroke_width
    def stroke_width=(w)
      @stroke_width = w
      @gc.set_line_width(w)
    end

    attr_reader :fill_color
    def fill_color=(c)
      @fill_color = c
      @gc.set_background(make_color(c))
    end

    def push_style(style)
      yield
    end
              
    def draw_line(x1, y1, x2, y2) 
      @gc.draw_line(x1, y1, x2, y2)
    end

    def draw_rectangle(x1, y1, x2, y2) 
      @gc.draw_rectangle(x1, y1, x2, y2)
    end

    def draw_ellipse(x1, y1, x2, y2) 
      @gc.draw_ellipse(x1, y1, x2, y2)
    end

    def draw_polygon(points)
      ps = points.flatten(1)
      @gc.fill_polygon(ps) if stroke_color
      @gc.draw_polygon(ps) 
    end

    def draw_lines(points)
      ps = points.flatten(1)
      @gc.draw_polyline(ps)
    end
    
    def draw_spline(points)
      ps = points.flatten(1)
      @gc.draw_polyline(ps)
    end
    
    def draw_text(str, x, y, angle=0)
      @gc.draw_text(str, x, y)
    end
    
    def get_text_extent(str)
      p = @gc.text_extent(str)
      return p.x, p.y
    end
  end
  
  class Color
    def initialize(r, g, b)
      return org.eclipse.swt.graphics.Color.new(@display, r, g, b)
    end
  end

  class Point
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
end

if __FILE__ == $0 then

  class TestWindow < GUI::Window
    def initialize
      super("Test Window")
      
      @window.setLayout(org.eclipse.swt.layout.RowLayout.new)
      org.eclipse.swt.widgets.Button.new(@window, \
                   org.eclipse.swt.SWT::PUSH).setText("Click me!")
    end
    
    def on_paint(gc, rect, count)
      w, h = get_client_size()
      gc.draw_line(0, 0, w, h)
    end
  end    

  GUI::Application.run do
    TestWindow.new.show
  end
end
