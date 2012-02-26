
# apply the stencil to the data to get a diagram (with Menu/action hooks?)
# compute the size/positions of the diagram (relative to window size)
# Display the diagram
# Process mouse clicks as actions

require 'core/diagram/code/diagram'
require 'core/schema/tools/print'
require 'core/system/library/schema'
require 'core/diagram/code/construct'
require 'core/expr/code/eval'
require 'core/expr/code/lvalue'
require 'core/expr/code/env'
require 'yaml' 

# render(Stencil, data) = diagram

def RunStencilApp(path = ARGV[0])
  Wx::App.run do
    win = StencilFrame.new(path)
    win.show 
  end
end

class StencilFrame < DiagramFrame
  attr_reader :selection

  include Paths

  class FunDefs; end

  def initialize(path = nil)
    super("Model Editor")
    @actions = {}
    @fundefs = FunDefs.new
    self.path = path if path
  end
  
  attr_writer :stencil
  
  def path=(path)
    ext = File.extname(path)
    raise "File has no extension" if ext.length < 2
    @path = path
    set_title path
    setup ext[1..-1], Load(@path)
  end
  
  def setup extension, data
    @extension = extension
    @stencil = Load("#{@extension}.stencil")
    if !@stencil.title.nil?
      self.set_title(@stencil.title)
    end
    @data = data
    if data.factory.file_path
      pos = "#{data.factory.file_path}-positions"
      #puts "FINDING #{pos}"
      @position_map = {}
      if File.exists?(pos)
        @position_map = YAML::load_file(pos)
      end
    end
    build_diagram
  end

  def rebuild_diagram
    capture_positions
    build_diagram
  end
  
  def build_diagram
    puts "REBUILDING"
    white = @factory.Color(255, 255, 255)
    black = @factory.Color(0, 0, 0)

    env = {
      @stencil.root => @data,
      :font => @factory.Font("Helvetica", 12, "swiss", 400, black),
      :pen => @factory.Pen(1, "solid", black),
      :brush => @factory.Brush(white)
    }

    @shapeToAddress = {}  # used for text editing
    @shapeToModel = {}    # list of all created objects
    @shapeToTag = {}    # list of all created objects
    @tagModelToShape = {}
    @connectors = []
    @stencil.body.each do |c|
      construct c, env, nil do |x|
        set_root(x)
      end
    end

    if !@position_map['*WINDOW*'].nil?
      size = @position_map['*WINDOW*']
      set_size(Wx::Size.new(size['x'], size['y']))
    end

    refresh()
    #puts "DONE"
    #Print.print(@root)
  end
	
	def lookup_shape(shape)
	  return @shapeToModel[shape]
	end
  
  def setup_menus()
    super()
    file = self.menu_bar.get_menu( self.menu_bar.find_menu("File") )
    add_menu(file, "&Export\tCmd-E", "Export Diagram", :on_export)
  end

  def on_open
    dialog = FileDialog.new(self, "Choose a file", "", "", "Model files (*.*)|*.*")
    if dialog.show_modal() == ID_OK
      self.path = dialog.get_path
    end
  end
  
  def on_save
    grammar = Loader.load("#{@extension}.grammar")
    File.open("#{@path}-NEW", "w") do |output|
      DisplayFormat.print(grammar, @data, 80, output)
    end

    capture_positions    
    #puts @position_map
    File.open("#{@path}-positions", "w") do |output|
      YAML.dump(@position_map, output)
    end
  end
  
  def capture_positions
    # save the position_map
    @position_map = {}
    @position_map["*VERSION*"] = 2

    size = get_size
    @position_map['*WINDOW*'] = {'x'=>size.get_width, 'y'=>size.get_height}

    obj_handler = lambda do |tag, obj, shape|
      @position_map[tag] = position(shape)
    end
    connector_handler = lambda do |tag, at1, at2|
      @position_map[tag] = [ EnsoPoint.new(at1.x, at1.y), EnsoPoint.new(at2.x, at2.y) ]
    end
    generate_saved_positions obj_handler, connector_handler, 9999 # no version on saving
  end
 
  def generate_saved_positions(obj_handler, connector_handler, version) 
    @tagModelToShape.each do |tagObj, shape|
      label = tagObj[0]
      obj = tagObj[1]
      begin
        if version == 1
          tag = obj.name
        else
          tag = "#{label}:#{obj._path.to_s}"
        end
        obj_handler.call tag, obj, shape
      rescue
      end
    end
    @connectors.each do |conn|
      ce1 = conn.ends[0]
      ce2 = conn.ends[1]
      obj1 = @shapeToModel[ce1.to]
      obj2 = @shapeToModel[ce2.to]
      begin
        if version == 1
          k = obj1.name
          l = ce1.label.string if ce1.label
          tag = "#{k}.#{l}"
        else
          label = @shapeToTag[ce1.to]
          l = "#{ce1.label && ce1.label.string}*#{ce2.label && ce2.label.string}"
          tag = "#{label}:#{obj1._path.to_s}:#{obj2._path.to_s}$#{l}"
        end
        connector_handler.call tag, ce1.attach, ce2.attach
      rescue
      end
    end
  end
    
  def do_constraints
    super
    return if !@position_map
    obj_handler = lambda do |tag, obj, shape|
      pos = @positions[shape]  # using Diagram private member
      pnt = @position_map[tag]
      #puts "   Has POS #{obj} #{pos} #{pnt}"
      if pos && pnt
        pos.x.value = pnt.x
        pos.y.value = pnt.y
      end
    end
    connector_handler = lambda do |tag, at1, at2|
      pnt = @position_map[tag]
      if pnt
        at1.x = pnt[0].x
        at1.y = pnt[0].y
        at2.x = pnt[1].x
        at2.y = pnt[1].y
      end
    end
    generate_saved_positions obj_handler, connector_handler, @position_map["*VERSION*"] || 1
  end
 
 
  
    # ------- event handling -------  
  def on_double_click(e)
    clear_selection
    text = find e, &:Text?
    if text
      address = @shapeToAddress[text]
      edit_address(address, text) if address
    end
  end
	
  def edit_address(address, shape)
    if address.type.Primitive?
			@selection = TextEditSelection.new(self, shape, address)
	  else
      pop = Wx::Menu.new
      find_all_objects @data, address.field.type do |obj|
        name = ObjectKey(obj)
    		add_menu2 pop, name, name do |e| 
    			address.value = obj
    			shape.string = name
    	  end
      end
	    r = boundary(shape)
      popup_menu(pop, Wx::Point.new(r.x, r.y))
	  end
  end
  

  def on_right_down(e)
    clear_selection
    actions = {}
    find e do |part|
      actions.update @actions[part] if @actions[part]
		  false
    end      
    if actions != {}
      pop = Wx::Menu.new
      actions.each do |name, action|
    		add_menu(pop, name, name, action) 
      end
      popup_menu(pop, Wx::Point.new(e.x, e.y))
    end
  end

  def connection_other_end(ce)
    conn = ce.connection
    return conn.ends[0] == ce ? conn.ends[1] : conn.ends[0]
  end    

  def on_export
    grammar = Loader.load("diagram.grammar")
    File.open("#{@path}-diagram", "w") do |output|
      DisplayFormat.print(grammar, @root, 80, output)
    end
  end

	def add_action shape, name, &block
	  @actions[shape] = {} if !@actions[shape]
	  @actions[shape][name] = block
	end
	    
  def construct(stencil, env, container, &block)
    send("construct#{stencil.schema_class.name}", stencil, env, container, &block)
  end
  
  def make_styles(stencil, shape, env)
    newEnv = nil
    font = nil
    pen = nil
    brush = nil
    #Print.print(stencil)
    newEnv = env.clone
    stencil.props.each do |prop|
      val = eval(prop.exp, newEnv, true)
      #puts "SET #{prop.loc} = #{val}"
      case "#{prop.loc.e.name}.#{prop.loc.fname}"
      when "font.size" then
        #puts "FONT SIZE #{val}"
        newEnv[:font] = font = env[:font]._clone if !font
        font.size = val
      when "font.weight" then
        font = newEnv[:font] = env[:font]._clone if !font
        font.weight = val
      when "line.width" then
        #puts "PEN #{val} for #{stencil}"
        pen = newEnv[:pen] = env[:pen]._clone if !pen
        pen.width = val
      when "line.color" then
        pen = newEnv[:pen] = env[:pen]._clone if !pen
        pen.color = val
      when "fill.color" then
        brush = newEnv[:brush] = env[:brush]._clone if !brush
        brush.color = val
      end
    end
    # TODO: why do I need to set the style on every object????
    shape.styles << (font || env[:font])
    shape.styles << (pen || env[:pen])
    shape.styles << (brush || env[:brush])
  end

  def constructAlt(this, env, container, &block)
    this.alts.each do |alt|
      catch :fail do
        return construct(alt, env, container, &block)
      end
    end
    throw :fail
  end

  def constructEAssign(this, env, container, &block)
    nenv = env.clone
      #presumably only Fields and Vars can serve as l-values
      #FIXME: handle Fields as well, by using the address field from eval
    lvalue(this.var, nenv).value = eval this.val, nenv
    construct this.body, nenv, container, &block
  end

  def constructEImport(this, env, container, &block)
    @fundefs.instance_eval(File.open(this.path, "r").read)
    @fundefs.singleton_methods.each do |m|
     env["#{m}"] = @fundefs.method(m)
    end
  end

  def constructEFor(this, env, container, &block)
    source = eval(this.list, env)
    address = lvalue(this.list, env)

    is_traversal = false
    if this.list.EField?
      lhs = eval(this.list.e, env)
      is_traversal = lhs.schema_class.fields[this.list.fname].traversal
    end

    nenv = env.clone
    source.each_with_index do |v, i|
      nenv[this.var] = v
      nenv[this.index] = i if this.index
      construct this.body, nenv, container do |shape|
        if this.label
          action = is_traversal ? "Delete" : "Remove"
	        add_action shape, "#{action} #{this.label}" do
	          if is_traversal
  	          v.delete!
  	        else
  	          addr.value = nil
  	        end
  	        rebuild_diagram
	        end
	      end
     		block.call shape
      end
    end
    if this.label
      action = is_traversal ? "Create" : "Add"
      begin
	      shape = @tagModelToShape[addr.object.name]
	    rescue
	    end
	    shape = container if !shape
	    #puts "#{action} #{this.label} #{address.object}.#{address.field} #{shape}"
	    add_action shape, "#{action} #{this.label}" do
	      if !is_traversal
	      	# just add a reference!
	      	#puts "ADD #{action}: #{address.field}"
	      	@selection = FindByTypeSelection.new self, address.type do |x|
			      address.value << x
						rebuild_diagram
			    end
	      else
		      factory = address.object.factory
			    obj = factory[address.type.name]
#			    relateField = nil
			    obj.schema_class.fields.each do |field|
			      #puts "FIELD: #{field}"
			      if field.key && field.type.Primitive? && field.type.name == "str"
			        obj[field.name] = "<#{field.name}>"
			      elsif !field.optional && !field.type.Primitive? && !(field.inverse && field.inverse.traversal)
			        obj[field.name] = find_default_object(@data, field.type)
#			        raise "Can't have two related field" if relateField
#			        relateField = field
			      end
			    end
	      	#puts "CREATE #{address.field} << #{obj}"
#	      	if relateField
#  	      	puts "ADD #{action}: #{addr.field}"
#		      	@selection = FindByTypeSelection.new self, addr.field.type do |x|
#		      	  obj[relateField.name] = x
#				      addr.insert obj
#							rebuild_diagram
#				    end
#	      	else
			      address.value << obj
			      #Print.print(@data)
	  				rebuild_diagram
#	  		  end
	      end
	    end
	  end
	end

	def find_default_object(scan, type)
	  catch :FoundObject do 
		  find_all_objects scan, type do |x|  
		    throw :FoundObject, x
		  end
		end
	end
	
	def find_all_objects(scan, type, &block)
	  return nil if !scan
	  puts "looking for #{type.name} as #{scan}"
          #block.call(scan) if scan._subtypeOf(scan.schema_class, type)
          block.call(scan) if Subclass?(scan.schema_class, type)
          scan.schema_class.fields.each do |field|
            if field.traversal
              if field.many
                scan[field.name].each do |x|
                  find_all_objects(x, type, &block)
                end
              else
                find_all_objects(scan[field.name], type, &block)
              end
            end
          end
          return nil
	end

  def constructEIf(this, env, container, &block)
    test = eval(this.cond, env)
    if test
      construct(this.body, env, container, &block)
    elsif !this.body2.nil?
      construct(this.body2, env, container, &block)
    end
  end

  def constructEBlock(this, env, container, &block)
    this.body.each do |command|
      construct(command, env, container, &block)
    end
  end

  def constructLabel(this, env, container, &block)
    construct this.body, env, container do |shape|
      tag, obj = evallabel(this.label, env)
      #puts "LABEL #{obj} => #{shape}"
      @tagModelToShape[[tag, obj]] = shape
      @shapeToModel[shape] = obj
      @shapeToTag[shape] = tag
      block.call(shape)
    end
  end

  def evallabel(label, env)
    tag = "default"
    if label.ESubscript? # it has the form Loc[foo]
      tag = label.e
      label = label.sub
      raise "foo" if !tag.Var?
      tag = tag.name
    end
    obj = eval(label, env)
    return tag, obj
  end
  
  # shapes
  def constructContainer(this, env, container, &block)
    if this.direction == 4
      this.items.each do |item|
        construct item, env, container, &block
      end
    else
      group = @factory.Container
      group.direction = this.direction
      this.items.each do |item|
        construct item, env, group do |x|
          group.items << x
        end
      end
      make_styles(this, group, env)
      block.call group if block
    end
  end
  
  def constructText(this, env, container, &block)
    val = eval(this.string, env, true)
    addr = lvalue(this.string, env)
    text = @factory.Text
    if val.is_a? Variable
      text.string = val.new_var_method do |a, *other|
        x = "#{a}"
      end
    else
      text.string = val.to_s
    end
    make_styles(this, text, env)
    if addr
	    @shapeToAddress[text] = addr
	  end
    block.call text
  end
  
  def constructShape(this, env, container, &block)
    shape = @factory.Shape # not many!!!
    shape.kind = this.kind
    construct this.content, env, shape do |x|
      error "Shape can only have one element" if shape.content
      shape.content = x
    end
    make_styles(this, shape, env)
    block.call shape
  end

  def makeLabel(exp, env)
    labelStr = eval(exp, env, true)
    if labelStr
      label = @factory.Text
      label.string = labelStr
      return label
    end
    return nil
  end
  
  def constructConnector(this, env, container, &block)
    conn = @factory.Connector
    @connectors << conn
    ptemp = [ @factory.EdgePos(0.5, 1), @factory.EdgePos(0.5, 0) ]
    i = 0
    this.ends.each do |e|
      label = e.label.nil? ? nil : makeLabel(e.label, env)
      other_label = e.other_label.nil? ? nil : makeLabel(e.other_label, env)
      de = @factory.ConnectorEnd(e.arrow, label, other_label)
      tag, obj = evallabel(e.part, env)
      x = @tagModelToShape[[tag, obj]]
      fail("Shape #{obj} does not exist in #{@tagModelToShape}") if x.nil?
      de.to = x
      de.attach = ptemp[i]
      i = i + 1
      
      #puts "END #{labelStr}"
      conn.ends << de
    end
    # DEFAULT TO BOTTOM OF FIRST ITEM, AND LEFT OF THE SECOND ONE
    
    make_styles(this, conn, env)
    block.call conn
  end

  #### expressions

  def eval(exp, env, dynamic = false)
    @eval = Interpreter(EvalExpr, EvalStencil) if @eval.nil?
    @eval.eval(exp, :env=>env, :dynamic=>dynamic, :factory=>@factory)
  end

  def lvalue(exp, env)
    @lval = Interpreter(LValueExpr) if @lval.nil?
    @lval.lvalue(exp, :env=>env, :factory=>@factory)
  end

end

class TextEditSelection
  def initialize(diagram, edit, address)
    @address = address
    @diagram = diagram  
    @edit_selection = edit
    r = diagram.boundary(@edit_selection)
    n = 3
    #puts r.x, r.y, r.w, r.h
    extraWidth = 10
    @edit_control = Wx::TextCtrl.new(diagram, 0, "", 
      Point.new(r.x - n, r.y - n), Size.new(r.w + 2 * n + extraWidth, r.h + 2 * n),
      0)  # Wx::TE_MULTILINE
    
    style = Wx::TextAttr.new()
    style.set_text_colour(diagram.makeColor(diagram.foreground))
    style.set_font(diagram.makeFont(diagram.font))      
    @edit_control.set_default_style(style)
    
    @edit_control.append_text(@edit_selection.string)
    @edit_control.show
    @edit_control.set_focus
  end

  def clear
    new_text = @edit_control.get_value()
    @address.value = new_text
    @edit_selection.string = new_text
    @edit_control.destroy
    return nil
  end

  def on_mouse_down(e)
  end

  def on_move(e, down)
  end

  def on_paint(dc)
  end
  
  def is_selected(part)
  end
end

class FindByTypeSelection
	def initialize(diagram, kind, &action)
	  @diagram = diagram
	  @part = nil
    @kind = kind
    @action = action
  end
  
  def on_move(e, down)
    #puts "CHECKING"
    @part = @diagram.find e do |shape| 
      obj = @diagram.lookup_shape(shape)
      #obj && obj._subtypeOf(obj.schema_class, @kind)
      obj && Subclass?(obj.schema_class, @kind)
    end
  end
  
  def is_selected(check)
    return @part == check
  end
  
  def on_paint(dc)
  end

  def on_mouse_down(e)
    @action.call(@diagram.lookup_shape(@part)) if @part
    return :cancel
	end
	 
  def clear
  end
end





if __FILE__ == $0 then
  RunStencilApp()
end
