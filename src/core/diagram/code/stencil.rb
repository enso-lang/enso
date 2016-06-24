
# apply the stencil to the data to get a diagram (with Menu/action hooks?)
# compute the size/positions of the diagram (relative to window size)
# Display the diagram
# Process mouse clicks as actions

require 'core/diagram/code/diagram'
require 'core/schema/tools/print'
require 'core/system/load/load'
require 'core/grammar/render/layout'
require 'core/system/library/schema'
# require 'core/diagram/code/construct'
require 'core/expr/code/eval'
require 'core/expr/code/lvalue'
# require 'core/expr/code/env'
require 'core/semantics/code/interpreter'
require 'core/expr/code/renderexp'
#require 'core/system/utils/paths'

# require 'core/expr/code/render'

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
	      @position_map = {}
	      if File.exists?(pos)
	        @position_map = System.readJSON(pos)
	        @position_map.each { |key, val|
						puts("LOC #{key}=#{val}")	          
	        }
	      end
	    end
	  end

	  def build_diagram
	    puts "REBUILDING"
	    white = @factory.Color(255, 255, 255)
	    black = @factory.Color(0, 0, 0)
	
	    env = {font: @factory.Font(nil, nil, nil, 12, "swiss"), pen: @factory.Pen(1, "solid", black), brush: @factory.Brush(white), nil: nil}
	    env[@stencil.root] = @data
	
	    @shapeToAddress = {}  # used for text editing
	    @shapeToModel = {}    # list of all created objects
	    @shapeToTag = {}    # list of all created objects
	    @tagModelToShape = {}
	    @connectors = []
      construct @stencil.body, env, nil, Proc.new {|x| set_root(x)}
	
#	    if !@position_map['*WINDOW*'].nil?
#	      size = @position_map['*WINDOW*']
#	      # set_size(Size.new(size['x'], size['y']))
#	    end
	
#	    refresh()
	    puts "DONE"
#	    Print.print(@root)
	  end
		
		def lookup_shape(shape)
			@shapeToModel[shape]
		end


	  def setup_menus()
	    super("FOO")
	    file = self.menu_bar.get_menu( self.menu_bar.find_menu("File") )
	    add_menu(file, "&Export\tCmd-E", "Export Diagram", :on_export)
	  end
	
	  def on_open
	    Proc.new {
		    dialog = FileDialog.new(self, "Choose a file", "", "", "Model files (*.*)|*.*")
		    if dialog.show_modal() == ID_OK
		      self.path = dialog.get_path
		    end
		  }
	  end
	  
	  def on_save
	    grammar = Load.load("#{@extension}.grammar")
	    File.write("#{@path}-NEW") do |output|
	      Layout::DisplayFormat.print(grammar, @data, output)
	    end
	
	    capture_positions    
	    #puts @position_map
#	    File.write("#{@path}-positions") do |output|
        System.writeJSON("#{@path}-positions", @position_map)
#	    end
	  end
	  
	  def capture_positions
	    # save the position_map
	    @position_map = {}
	    @position_map["*VERSION*"] = 2
	
	    @position_map['*WINDOW*'] = {x: @win.width_, y: @win.height_}
	
	    obj_handler = Proc.new { |tag, obj, shape|
	      @position_map[tag] = position(shape)
	    }
	    connector_handler = Proc.new { |tag, at1, at2|
	      @position_map[tag] = [ EnsoPoint.new(at1.x, at1.y), EnsoPoint.new(at2.x, at2.y) ]
	    }
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
	    super("FOO")
	    if @position_map
		    @position_map.each do |key, pnt|
		      #puts "CHECK #{key} #{pnt}"
		      field = nil
		      parts = key.split('.')
		      if parts.size == 2
		        key = parts[0]
		        field = parts[1]
		      end
		      obj = @labelToShape[key]
		      if !obj.isnil?
			      #puts "   Has OBJ #{key} #{pnt} #{obj.connectors}"
			      if field.nil?
				      pos = @positions[obj]
				      if !pos.isnil?
					      #puts "   Has POS #{key} #{pnt}"
					      pos.x.value = pnt.x
					      pos.y.value = pnt.y
					    end
				    else
				      obj.connectors.find do |ce|
			          l = ce.label ? ce.label.string : ""
				        #puts "   CHECKING #{l}"
			          if field == l
			            conn = ce.owner
			            #puts "   Has ATTACH #{field}"
			            conn.ends[0].attach.x = pnt[0].x
			            conn.ends[0].attach.y = pnt[0].y
			            conn.ends[1].attach.x = pnt[1].x
			            conn.ends[1].attach.y = pnt[1].y
			            true
				        end
				      end
				    end
				  end
				end
			end
	    if @position_map
		    obj_handler = Proc.new {|tag, obj, shape|
		      pos = @positions[shape]  # using Diagram private member
		      pnt = @position_map[tag]
		      #puts "   Has POS #{obj} #{pos} #{pnt}"
		      if pos && pnt
		        pos.x.value = pnt.x
		        pos.y.value = pnt.y
		      end
		    }
		    connector_handler = Proc.new { |tag, at1, at2|
		      pnt = @position_map[tag]
		      if pnt
		        at1.x = pnt[0].x
		        at1.y = pnt[0].y
		        at2.x = pnt[1].x
		        at2.y = pnt[1].y
		      end
		    }
		    generate_saved_positions obj_handler, connector_handler, @position_map["*VERSION*"] || 1
		  end
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
#		    r = boundary(shape)
#	      popup_menu(pop, Point.new(r.x, r.y))
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
#	      popup_menu(pop, Point.new(e.x, e.y))
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
		    
	  def construct(stencil, env, container, proc)
	    send("construct#{stencil.schema_class.name}", stencil, env, container, proc)
	  end
	  
	  def make_styles(stencil, shape, env)
	    newEnv = nil
	    font = nil
	    pen = nil
	    brush = nil
	    #Print.print(stencil)
	    newEnv = env.clone
	    stencil.props.each do |prop|
	      val = eval(prop.exp, newEnv) # , true)
	      #puts "SET #{prop.loc} = #{val}"
	      case Interpreter(Renderexp::RenderExpr).render(prop.loc)
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
	
	  def constructAlt(this, env, container, proc)
	    this.alts.find do |alt|
	      construct(alt, env, container, proc)
	    end
	  end
	
	  def constructEAssign(this, env, container, proc)
	    nenv = env.clone
	      #presumably only Fields and Vars can serve as l-values
	      #FIXME: handle Fields as well, by using the address field from eval
	    lvalue(this.var, nenv).value = eval(this.val, nenv)
	    construct this.body, nenv, container, proc
	  end
	
	  def constructEImport(this, env, container, proc)
	    #@fundefs.instance_eval(File.open(this.path, "r").read)
	    #@fundefs.singleton_methods.each do |m|
	    # env["#{m}"] = @fundefs.method(m)
	    #end
	  end
	
	  def constructEFor(this, env, container, proc)
	    source = eval(this.list, env)
	    # address = lvalue(this.list, env)
	
	    is_traversal = false
	    if this.list.EField?
	      lhs = eval(this.list.e, env)
	      f = lhs.schema_class.all_fields[this.list.fname]
	      raise "MISSING #{this.list.fname} on #{lhs.schema_class}" if !f
	      is_traversal = f.traversal
	    end
	
	    nenv = env.clone
	    source.each_with_index do |v, i|
	      nenv[this.var] = v
	      nenv[this.index] = i if this.index
	      construct(this.body, nenv, container, Proc.new { |shape|
	        if this.label
	          action = is_traversal ? "Delete" : "Remove"
		        add_action(shape, "#{action} #{this.label}") do
		          if is_traversal
	  	          v.delete!
	  	        else
	  	          addr.value = nil
	  	        end
		        end
		      end
	     		proc.call shape
	      })
	    end
	    if this.label
	      action = is_traversal ? "Create" : "Add"
	      begin
		      shape = @tagModelToShape[addr.object.name]
		    rescue
		    end
		    shape = container if !shape
		    #puts "#{action} #{this.label} #{address.object}.#{address.field} #{shape}"
		    add_action(shape, "#{action} #{this.label}") do
		      if !is_traversal
		      	# just add a reference!
		      	#puts "ADD #{action}: #{address.field}"
		      	@selection = FindByTypeSelection.new self, address.type do |x|
				      address.value << x
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
	
	  def constructEIf(this, env, container, proc)
	    test = eval(this.cond, env)
	    if test
	      construct(this.body, env, container, proc)
	    elsif !this.body2.nil?
	      construct(this.body2, env, container, proc)
	    end
	  end
	
	  def constructEBlock(this, env, container, proc)
	    this.body.each do |command|
	      construct(command, env, container, proc)
	    end
	  end
	
	  def constructLabel(this, env, container, proc)
	    construct this.body, env, container, Proc.new { |shape|
	      info = evallabel(this.label, env)
	      tag = info[0] 
	      obj = info[1]
	      #puts "LABEL #{obj} => #{shape}"
	      @tagModelToShape[[tag, obj]] = shape
	      @shapeToModel[shape] = obj
	      @shapeToTag[shape] = tag
	      proc.call(shape)
	    }
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
	    [tag, obj]
	  end
	  
	  # shapes
	  def constructContainer(this, env, container, proc)
	    if this.direction == 4
	      this.items.each do |item|
	        construct item, env, container, proc
	      end
	    else
	      group = @factory.Container
	      group.direction = this.direction
	      this.items.each do |item|
	        construct item, env, group, Proc.new { |x|
	          group.items << x
	        }
	      end
	      make_styles(this, group, env)
	      proc.call group if proc
	    end
	  end
	  
	  def constructText(this, env, container, proc)
	    val = eval(this.string, env) # , true)
	    addr = nil # lvalue(this.string, env)
	    text = @factory.Text
#	    if val.is_a? Variable
#	      text.string = val.new_var_method do |a, *other|
#	        x = "#{a}"
#	      end
#	    else
	      text.string = val.to_s
#	    end
	    text.editable = this.editable
	    make_styles(this, text, env)
	    if addr
		    @shapeToAddress[text] = addr
		  end
	    proc.call text
	  end
	  
	  def constructShape(this, env, container, proc)
	    shape = @factory.Shape # not many!!!
	    shape.kind = this.kind
	    construct this.content, env, shape, Proc.new { |x|
	      error "Shape can only have one element" if shape.content
	      shape.content = x
	    }
	    make_styles(this, shape, env)
	    proc.call shape
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
	  
	  def constructConnector(this, env, container, proc)
	    conn = @factory.Connector
	    @connectors << conn
	    ptemp = [ @factory.EdgePos(0.5, 1), @factory.EdgePos(0.5, 0) ]
	    i = 0
	    this.ends.each do |e|
	      label = e.label.nil? ? nil : makeLabel(e.label, env)
	      other_label = e.other_label.nil? ? nil : makeLabel(e.other_label, env)
	      de = @factory.ConnectorEnd(e.arrow, label, other_label)
	      info = evallabel(e.part, env)
	      tag = info[0]
	      obj = info[1]
	      x = @tagModelToShape[[tag, obj]]
	      fail("Shape #{[tag, obj]} does not exist in #{@tagModelToShape}") if x.nil?
	      de.to = x
	      de.attach = ptemp[i]
	      i = i + 1
	      
	      #puts "END #{labelStr}"
	      conn.ends << de
	    end
	    # DEFAULT TO BOTTOM OF FIRST ITEM, AND LEFT OF THE SECOND ONE
	    
	    make_styles(this, conn, env)
	    proc.call conn
	  end
	
	  #### expressions
	  
	  def eval(exp, env)
	    Eval::eval(exp, env: env)
	  end
	     	
	  def lvalue(exp, env)
	    @lval = Interpreter(LValueExpr) if @lval.nil?
	    @lval.lvalue(exp, env: env, factory: @factory)
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
	    @edit_control = TextCtrl.new(diagram, 0, "", Point.new(r.x - n, r.y - n), Size.new(r.w + 2 * n + extraWidth, r.h + 2 * n), 0)  # Wx::TE_MULTILINE
	    
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
	    @part == check
	  end
	  
	  def paint(dc)
	  end
	
	  def on_mouse_down(e)
	    @action.call(@diagram.lookup_shape(@part)) if @part
	    :cancel
		end
		 
	  def clear
	  end
	end

end

