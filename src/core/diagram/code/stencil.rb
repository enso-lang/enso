
# apply the stencil to the data to get a diagram (with Menu/action hooks?)
# compute the size/positions of the diagram (relative to window size)
# Display the diagram
# Process mouse clicks as actions

require 'core/diagram/code/diagram'
require 'core/schema/tools/print'
require 'core/system/load/load'
require 'core/grammar/render/layout'
require 'core/system/library/schema'
require 'core/expr/code/eval'
require 'core/expr/code/lvalue'
require 'core/semantics/code/interpreter'
require 'core/expr/code/renderexp'

module Stencil
	
	class StencilFrame < Diagram::DiagramFrame
	  attr_reader :selection
	
	  #class FunDefs; end
	
	  def initialize(win, canvas, context, path = nil)
	    super(win, canvas, context, "Model Editor")
	    @actions = {}
	    # @fundefs = FunDefs.new
	    self.path = path if path
	  end

	  attr_writer :stencil
	  
	  def path=(path)
	    puts "Opening #{path}"
	    ext = path.substr(path.lastIndexOf('.')+1)
	    raise "File has no extension" if ext.size < 2
	    @path = path
	    # set_title path
	    setup ext, Load::load(@path)
	  end
	 
	  def setup(extension, data)
	    @extension = extension
	    @stencil = Load::load("#{@extension}.stencil")
	    if !@stencil.title.nil?
	      self.set_title(@stencil.title)
	    end
	    @data = data
	    build_diagram

	    if data.factory.file_path[0]
	      pos = "#{data.factory.file_path[0]}-positions"
	      #puts "FINDING #{pos}"
	      if File.exists?(pos)
	        position_map = System.readJSON(pos)
				  set_positions(position_map)
			    if !position_map['*WINDOW*'].nil?
			      size = position_map['*WINDOW*']
			      # set_size(size['x'], size['y'])
		      end
	      end
	    end
	    clear_refresh
	  end

	  def set_positions(position_map)
	    @graphShapes.each do |tag, shape|
        pnt = position_map[tag]
        if pnt
		      if shape.Connector?
			      at1 = shape.ends[0].attach
			      at2 = shape.ends[1].attach
		        at1.x = pnt[0].x_
		        at1.y = pnt[0].y_
		        at2.x = pnt[1].x_
		        at2.y = pnt[1].y_
					else
			      pos = @positions[shape]  # using Diagram private member
			      #puts "   Has POS #{pos} #{pnt}"
			      if pos
			        pos.x.value = pnt.x_
			        pos.y.value = pnt.y_
			      end
			    end
			  end
		  end
	  end

	  def build_diagram
	    puts "REBUILDING"
	    white = @factory.Color(255, 255, 255)
	    black = @factory.Color(0, 0, 0)
		
	    env = {font: @factory.Font(nil, nil, nil, 14, "sans-serif"), pen: @factory.Pen(1, "solid", black), brush: @factory.Brush(black), nil: nil}
	    env[@stencil.root] = @data
	
	    @shapeToAddress = {}  # used for text editing
	    @shapeToModel = {}    # list of all created objects
	 #   @shapeToTag = {}    # list of all created objects
	    @tagModelToShape = {}
	    @graphShapes = {}
	    @connectors = []
      construct @stencil.body, env, nil, nil, Proc.new {|x, subid| set_root(x)}
	  end
		
#		def lookup_shape(shape)
#			@shapeToModel[shape]
#		end

	  def setup_menus()
	    super("FOO")
	    file = self.menu_bar.get_menu( self.menu_bar.find_menu("File") )
	    add_menu(file, "&Export\tCmd-E", "Export Diagram", :on_export)
	  end
	
		def do_open(file)
	    self.path = file.split('/')[-1]
		end
	  
	  def on_save
	    grammar = Load.load("#{@extension}.grammar")
	    pos = "#{@data.factory.file_path[0]}"    
	    File.write("#{pos}-NEW") do |output|
	      Layout::DisplayFormat.print(grammar, @data, output, false) #false => dont slash_kwywords
	    end
	
	    System.writeJSON("#{pos}-positions", capture_positions())
	  end
	  
	  def capture_positions
	    # save the position_map
	    position_map = System.JSHASH()
	    position_map["*VERSION*"] = 2
	
	    # position_map['*WINDOW*'] = {x: @win.width_, y: @win.height_}
	
	    @graphShapes.each do |tag, shape|
	      if shape.Connector?
		      at1 = shape.ends[0].attach
		      at2 = shape.ends[1].attach
		      h1 = System.JSHASH()
		      h2 = System.JSHASH()
		      h1.x_ = at1.x
		      h1.y_ = at1.y
		      h2.x_ = at2.x
		      h2.y_ = at2.y
		      position_map[tag] = [ h1, h2 ]
		    else
		      pos = position_fixed(shape)
		      hash = System.JSHASH()
		      hash.x_ = pos.x
		      hash.y_ = pos.y
		      position_map[tag] = hash
	      end
	    end
	    
	    position_map
	  end
	 
	    
	 
	  
#	    # ------- event handling ------- 
#=begin 
#	  def on_double_click(e)
#	    clear_selection
#	    text = find e, &:Text?
#	    if text and text.editable
#	      address = @shapeToAddress[text]
#	      edit_address(address, text) if address
#	    end
#	  end
#		
#	  def edit_address(address, shape)
#	    if address.type.Primitive?
#				@selection = TextEditSelection.new(self, shape, address)
#		  else
#	      pop = Menu.new
#	      find_all_objects @data, address.field.type do |obj|
#	        name = ObjectKey(obj)
#	    		add_menu2 pop, name, name do |e| 
#	    			address.value = obj
#	    			shape.string = name
#	    	  end
#	      end
#		    r = boundary_fixed(shape)
#	      popup_menu(pop, r.x, r.y)
#		  end
#	  end
#	  
#	
#	  def on_right_down(e)
#	    clear_selection
#	    actions = {}
#	    find e do |part|
#	      actions.update @actions[part] if @actions[part]
#			  false
#	    end      
#	    if actions != {}
#	      pop = Menu.new
#	      actions.each do |name, action|
#	    		add_menu(pop, name, name, action) 
#	      end
#	      popup_menu(pop, e.x, e.y)
#	    end
#	  end
#=end
	
#	  def connection_other_end(ce)
#	    conn = ce.connection
#	    conn.ends[0] == ce ? conn.ends[1] : conn.ends[0]
#	  end    
	
	  def on_export
	    grammar = Load.load("diagram.grammar")
	    File.write("#{@path}-diagram") do |output|
	      Layout::DisplayFormat.print(grammar, @root, output)
	    end
	  end
	
		def add_action(shape, name, &block)
		  @actions[shape] = {} if !@actions[shape]
		  @actions[shape][name] = block
		end
		    
	  def construct(stencil, env, container, id, proc)
	    send("construct#{stencil.schema_class.name}", stencil, env, container, id, proc)
	  end
	  
	  def make_styles(stencil, shape, env)
	    font = nil
	    pen = nil
	    brush = nil
	    #Print.print(stencil)
	    newEnv = env.clone
	    stencil.props.each do |prop|
	      val = eval(prop.exp, newEnv) # , true)
	      #puts "SET #{prop.loc} = #{val}"
	      case Renderexp.render(prop.loc)
	      when "font.size" then
	        #puts "FONT SIZE #{val}"
	        newEnv[:font] = font = env[:font]._clone if !font
	        font.size = val
	      when "font.weight" then
	        newEnv[:font] = font = env[:font]._clone if !font
	        font.weight = val
	      when "font.style" then
	        newEnv[:font] = font = env[:font]._clone if !font
	        font.style = val
	      when "font.variant" then
	        newEnv[:font] = font = env[:font]._clone if !font
	        font.variant = val
	      when "font.family" then
	        newEnv[:font] = font = env[:font]._clone if !font
	        font.family = val
	      when "font.color" then
	        newEnv[:font] = font = env[:font]._clone if !font
	        font.color = val
	      when "line.width" then
	        #puts "PEN #{val} for #{stencil}"
	        newEnv[:pen] = pen = env[:pen]._clone if !pen
	        pen.width = val
	      when "line.color" then
	        newEnv[:pen] = pen = env[:pen]._clone if !pen
	        pen.color = val
	      when "fill.color" then
	        newEnv[:brush] = brush = env[:brush]._clone if !brush
	        brush.color = val
	      end
	    end
	    # TODO: why do I need to set the style on every object????
	    shape.styles << font if font
	    shape.styles << pen if pen
	    shape.styles << brush if brush
	  end
	
	  def constructAlt(obj, env, container, id, proc)
	    obj.alts.find do |alt|
	      construct(alt, env, container, id, proc)
	    end
	  end
	
	  def constructEAssign(obj, env, container, id, proc)
	    nenv = env.clone
	      #presumably only Fields and Vars can serve as l-values
	      #FIXME: handle Fields as well, by using the address field from eval
	    lvalue(obj.var, nenv).value = eval(obj.val, nenv)
	    construct obj.body, nenv, container, id, proc
	  end
	
	  def constructEImport(obj, env, container, id, proc)
	    #@fundefs.instance_eval(File.open(obj.path, "r").read)
	    #@fundefs.singleton_methods.each do |m|
	    # env["#{m}"] = @fundefs.method(m)
	    #end
	  end
	
	  def constructEFor(obj, env, container, id, proc)
	    source = eval(obj.list, env)
	    # address = lvalue(obj.list, env)
	
	    is_traversal = false
	    if obj.list.EField?
	      lhs = eval(obj.list.e, env)
	      f = lhs.schema_class.all_fields[obj.list.fname]
	      raise "MISSING #{obj.list.fname} on #{lhs.schema_class}" if !f
	      is_traversal = f.traversal
	    end
	
	    nenv = env.clone
	    source.each_with_index do |v, i|
	      nenv[obj.var] = v
	      nenv[obj.index] = i if obj.index
	      
	      # make a location for each iteration
	      if v.schema_class.key
	        loc_name = v[v.schema_class.key.name]
	        if id
	        	newId = "#{id}.#{loc_name}"
	        else
	          newId = loc_name
	        end
	      else
	        newId = id
	      end  
	      construct(obj.body, nenv, container, newId, Proc.new { |shape, subid|
	        if obj.label
	          action = is_traversal ? "Delete" : "Remove"
		        add_action(shape, "#{action} #{obj.label}") do
		          if is_traversal
	  	          v.delete!
	  	        else
	  	          addr.value = nil
	  	        end
		        end
		      end
	     		proc.call shape, subid
	      })
	    end
	    if obj.label
	      action = is_traversal ? "Create" : "Add"
	      begin
		      shape = @tagModelToShape[addr.object.name]
		    rescue
		    end
		    shape = container if !shape
		    #puts "#{action} #{obj.label} #{address.object}.#{address.field} #{shape}"
		    add_action(shape, "#{action} #{obj.label}") do
#		      if !is_traversal
#		      	# just add a reference!
	#	      	#puts "ADD #{action}: #{address.field}"
		#      	@selection = FindByTypeSelection.new self, address.type do |x|
		#		      address.value << x
		#		    end
		 #     else
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
		#		    end
		      	#puts "CREATE #{address.field} << #{obj}"
	#	      	if relateField
	#  	      	puts "ADD #{action}: #{addr.field}"
	#		      	@selection = FindByTypeSelection.new self, addr.field.type do |x|
	#		      	  obj[relateField.name] = x
	#				      addr.insert obj
	#				    end
	#	      	else
				      address.value << obj
				      #Print.print(@data)
	#	  		  end
		      end
		    end
		  end
		end
	
	
		def find_default_object(scan, type)
		  catch :FoundObject do 
			  find_all_objects(scan, type) do |x|  
			    throw :FoundObject, x
			  end
			end
		end 
		
		def find_all_objects(scan, type, &block)
		  if scan
			  # puts "looking for #{type.name} as #{scan}"
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
	    end
		end
	
	  def constructEIf(obj, env, container, id, proc)
	    test = eval(obj.cond, env)
	    if test
	      construct(obj.body, env, container, id, proc)
	    elsif !obj.body2.nil?
	      construct(obj.body2, env, container, id, proc)
	    end
	  end
	
	  def constructEBlock(obj, env, container, id, proc)
	    obj.body.each do |command|
	      construct(command, env, container, id, proc)
	    end
	  end
	
	  def constructLabel(obj, env, container, id, proc)
	    construct obj.body, env, container, id, Proc.new { |shape, subid|
	      tag = evallabel(obj.label, env)
	      # puts "LABEL #{tag} / #{obj} => #{shape}"
	      @tagModelToShape[tag._path] = shape
	      proc.call(shape, subid)
	    }
	  end
	
	  def evallabel(label, env)
#	    tag = "default"
#	    if label.ESubscript? # it has the form Loc[foo]
#	      tag = label.e
#	      label = label.sub
#	      raise "foo" if !tag.Var?
#	      tag = tag.name
#	    end
	    obj = eval(label, env)
	  end
	  
	  # shapes
	  def constructContainer(obj, env, container, id, proc)
	    if obj.direction == 4
	      obj.items.each do |item|
	        construct item, env, container, id, proc
	      end
	    else
	      group = @factory.Container
	      group.direction = obj.direction
	      obj.items.each do |item|
	        construct item, env, group, id, Proc.new { |x, subid|
	          group.items << x
	          if obj.direction == 3
 	            @graphShapes[subid] = x
	            #puts "GRAPH #{subid} --> #{x}"
	          end
	        }
	      end
	      make_styles(obj, group, env)
	      proc.call group, id if proc
	    end
	  end
	  
	  def constructText(obj, env, container, id, proc)
	    val = eval(obj.string, env) # , true)
	    addr = nil # lvalue(obj.string, env)
	    text = @factory.Text
#	    if val.is_a? Variable
#	      text.string = val.new_var_method do |a, *other|
#	        x = "#{a}"
#	      end
#	    else
	      text.string = val.to_s
#	    end
	    text.editable = obj.editable
	    make_styles(obj, text, env)
	    if addr
		    @shapeToAddress[text] = addr
		  end
	    proc.call text, id
	  end
	  
	  def constructShape(obj, env, container, id, proc)
	    shape = @factory.Shape # not many!!!
	    shape.kind = obj.kind
	    construct obj.content, env, shape, nil, Proc.new { |x, subid|
	      error "Shape can only have one element" if shape.content
	      shape.content = x
	    }
	    make_styles(obj, shape, env)
	    proc.call shape, id
	  end
	
	  def makeLabel(exp, env)
	    labelStr = eval(exp, env) # true
	    if labelStr
	      label = @factory.Text
	      label.string = labelStr
	      label.editable = false
	      label
	    end
	  end
	  
	  def constructConnector(obj, env, container, id, proc)
	    conn = @factory.Connector
	    @connectors << conn
	    if obj.ends[0].label == obj.ends[1].label
		    ptemp = [ @factory.EdgePos(1, 0.5), @factory.EdgePos(1, 0.75) ]
	    else
		    ptemp = [ @factory.EdgePos(0.5, 1), @factory.EdgePos(0.5, 0) ]
		  end
	    i = 0
	    info = nil
	    label = nil
	    cend = nil
	    obj.ends.each do |e|
	      label = e.label.nil? ? nil : makeLabel(e.label, env)
	      other_label = e.other_label.nil? ? nil : makeLabel(e.other_label, env)
	      cend = @factory.ConnectorEnd(e.arrow, label, other_label)
	      info = evallabel(e.part, env)
	      x = @tagModelToShape[info._path]
	      fail("Shape #{info._path} does not exist in #{@tagModelToShape}") if x.nil?
	      cend.to = x
	      cend.attach = ptemp[i]
	      i = i + 1	      
	      conn.ends << cend
	    end
	    #tag = "#{info._path}:#{label.nil? ? "link" : label.string}"
	    #puts "CONNECTOR #{tag}"
	    #@tagModelToShape[tag] = cend
	    
	    # DEFAULT TO BOTTOM OF FIRST ITEM, AND LEFT OF THE SECOND ONE
	    
	    make_styles(obj, conn, env)
	    proc.call conn, id
	  end
	
	  #### expressions
	  
	  def lvalue(exp, env)
	    Lvalue.lvalue(exp, env: env, factory: @factory)
	  end

	  def eval(obj, env)
	    interp = Stencil::EvalColorC.new(self)
	    interp.dynamic_bind({env: env}) do
	      interp.eval(obj)
	    end
	  end

	end

  class EvalColorC
    include Eval::EvalExpr
    def initialize(d)
      @diagram = d
    end
    
    def eval_Color(this)
      @diagram.factory.Color(eval(this.r), eval(this.g), eval(this.b))
  	end
  end

	
	class TextEditSelection
	  def initialize(diagram, edit, address)
	    @address = address
	    @diagram = diagram  
	    @edit_selection = edit
	    r = diagram.boundary_fixed(@edit_selection)
	    n = 3
	    #puts r.x, r.y, r.w, r.h
	    extraWidth = 10
	    @edit_control = TextCtrl.new(diagram, 0, "", r.x - n, r.y - n, r.w + 2 * n + extraWidth, r.h + 2 * n, 0)  # Wx::TE_MULTILINE
	    
	    style = TextAttr.new()
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
	    nil
	  end
	
	end
	
#	class FindByTypeSelection
#		def initialize(diagram, kind, &action)
#		  @diagram = diagram
#		  @part = nil
#	    @kind = kind
#	    @action = action
#	  end
#	  
#	  def on_move(e, down)
#	    #puts "CHECKING"
#	    @part = @diagram.find e do |shape| 
#	      obj = @diagram.lookup_shape(shape)
#	      #obj && obj._subtypeOf(obj.schema_class, @kind)
#	      obj && Subclass?(obj.schema_class, @kind)
#	    end
#	  end
#	  
#	  def is_selected(check)
#	    @part == check
#	  end
#	  
#	  def do_paint(dc)
#	  end
#	
#	  def on_mouse_down(e)
#	    @action.call(@diagram.lookup_shape(@part)) if @part
#	    :cancel
#		end
#		 
#	  def clear
#	  end
#	end

end

