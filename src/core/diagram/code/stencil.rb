
# apply the stencil to the data to get a diagram (with Menu/action hooks?)
# compute the size/positions of the diagram (relative to window size)
# Display the diagram
# Process mouse clicks as actions

require 'core/diagram/code/diagram'
require 'yaml' 

# render(Stencil, data) = diagram

def RunStencilApp(path = nil)
  Wx::App.run do
    win = StencilFrame.new(path)
    win.show 
  end
end

class StencilFrame < DiagramFrame

  def initialize(path = nil)
    super("Diagram Editor")
    @actions = {}
    self.path = path if path
  end
  
  attr_writer :stencil
  
  def path=(path)
    ext = File.extname(path)
    raise "File has no extension" if ext.length < 2
    @extension = ext[1..-1]
    @stencil = Load("#{@extension}.stencil")
    @path = path
    set_title path
    @data = Load(@path)
    
    white = @factory.Color(255, 255, 255)
    black = @factory.Color(0, 0, 0)
        
    env = { 
      @stencil.root => @data,
      :font => @factory.Font("Helvetica", 12, "swiss", 400, black),
      :pen => @factory.Pen(1, "solid", black),
      :brush => @factory.Brush(white)
    }
    
    @nodeTable = {}
    @connectors = []
    construct @stencil.body, env, nil do |x| 
      set_root(x) 
    end
    #puts "FINDING #{path}-positions"
    @old_map = {}
    if File.exists?("#{path}-positions")
      @old_map = YAML::load_file("#{path}-positions")
    end
    refresh()
    #puts "DONE"
    #Print.print(@root)
  end

  def do_constraints
    super
    @old_map.each do |key, pnt|
      #puts "CHECK #{key} #{pnt}"
      field = nil
      if key =~ /(.*)\.(.*)/
        key = $1
        field = $2
      end
      obj = @nodeTable[key]
      next if !obj
      #puts "   Has OBJ #{key} #{pnt} #{obj.connectors}"
      begin
	      if field.nil?
		      pos = @positions[obj]
		      next if !pos
		      #puts "   Has POS #{key} #{pnt}"
		      pos.x.value = pnt.x
		      pos.y.value = pnt.y
		    else
		      obj.connectors.each do |ce|
	          l = ce.label ? ce.label.string : ""
		        #puts "   CHECKING #{l}"
	          if field == l
	            conn = ce.owner
	            #puts "   Has ATTACH #{field}"
	            conn.ends[0].attach.x = pnt[0].x
	            conn.ends[0].attach.y = pnt[0].y
	            conn.ends[1].attach.x = pnt[1].x
	            conn.ends[1].attach.y = pnt[1].y
	            break
		        end
		      end
		    end
	    rescue
	    end
    end
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

    # save the positions
    positions = {}
    inverse = {}
    @nodeTable.each do |key, obj|
      positions[key] = position(obj)
      inverse[obj] = key
    end
    @connectors.each do |conn|
      ce = conn.ends[0]
      ce2 = conn.ends[1]
      k = inverse[ce.to]
      l = ce.label.string if ce.label
      positions["#{k}.#{l}"] = [ EnsoPoint.new(ce.attach.x, ce.attach.y), EnsoPoint.new(ce2.attach.x, ce2.attach.y) ]
    end
    #puts positions
    File.open("#{@path}-positions", "w") do |output|
      YAML.dump(positions, output)
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

  def construct(stencil, env, container, &block)
    send("construct#{stencil.schema_class.name}", stencil, env, container, &block)
  end
  
  def make_styles(stencil, shape, env)
    newEnv = nil
    font = nil
    pen = nil
    brush = nil
    stencil.props.each do |prop|
      val, _ = eval(prop.exp, env)
      #puts "SET #{prop.loc.name} = #{val}"
      newEnv = {}.update(env) if !newEnv
      case prop.loc.name
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

  def constructFor(this, env, container, &block) 
    source, address = eval(this.iter, env)
    nenv = {}.update(env)
    kind = address.field.type.name
    source.each_with_index do |v, i|
      nenv[this.var] = v
      nenv[this.index] = i if this.index
      construct this.body, nenv, container do |shape|
        if this.label
          action = address.is_traversal ? "Delete" : "Remove"
	        add_action shape, "#{action} #{this.label} '#{v.name}'" do    # TODO: delete versus remove???
	          v.delete
	        end
	      end
     		block.call shape
      end
    end
    if this.label
      action = address.is_traversal ? "Create" : "Add"
      begin
	      shape = @nodeTable[address.obj.name]
	    rescue
	    end
	    shape = container if !shape
	    puts "#{action} #{this.label} #{address.obj} #{shape}"
	    add_action shape, "#{action} #{this.label}" do 
	      address.insert_new address.field.type
	    end
	  end
	end
	
	def add_action shape, name, &block
	  @actions[shape] = {} if !@actions[shape]
	  @actions[shape][name] = block
	end
	    
  def constructTest(this, env, container, &block)
    test, _ = eval(this.condition, env)
    construct(this.body, env, container, &block) if test
  end

  def constructLabel(this, env, container, &block)
    key = evallabel(this.label, env)
    construct this.body, env, container do |result|
      #puts "LABEL #{key} => #{result}"
      @nodeTable[key] = result
      block.call(result)
    end
  end

  def evallabel(label, env)
    if label.Prim? && label.op == "[]"   # it has the form Loc[foo]
      tag = label.args[0]
      raise "foo" if !tag.Var?
      tag = tag.name
      index, _ = eval(label.args[1], env)
      return "#{tag}_#{index.name}"  #TODO: hack!!! should use the real path
    else
      val, _ = eval(label, env)
      val = val.name  #TODO: hack!!!
      return val
    end
  end
  
  # shapes
  def constructContainer(this, env, container, &block)
    group = @factory.Container(nil, nil, this.direction)
    this.items.each do |item|
      construct item, env, group do |x|
        group.items << x
      end
    end
    make_styles(this, group, env)
    block.call group
  end
  
  def constructText(this, env, container, &block)
    val, address = eval(this.string, env)
    text = @factory.Text(nil, nil, val)
    make_styles(this, text, env)
    text.add_listener "string" do |val|
      address.value = val
    end
    block.call text
  end
  
  def constructShape(this, env, container, &block)
    shape = @factory.Shape(nil, nil) # not many!!!
    shape.kind = this.kind
    construct this.content, env, shape do |x|
      error "Shape can only have one element" if shape.content
      shape.content = x
    end
    make_styles(this, shape, env)
    block.call shape
  end

  def constructConnector(this, env, container, &block)
    conn = @factory.Connector(nil, nil, nil)
    @connectors << conn
    ptemp = [ @factory.EdgePos(0.5, 1), @factory.EdgePos(0.5, 0) ]
    i = 0
    this.ends.each do |e|
      labelStr, _ = eval(e.label, env)
      label = labelStr && @factory.Text(nil, nil, labelStr)
      labelStr, _ = eval(e.other_label, env)
      other_label = labelStr && @factory.Text(nil, nil, labelStr)
      de = @factory.ConnectorEnd(e.arrow, label, other_label)
      key = evallabel(e.part, env)
      de.to = @nodeTable[key]
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
  
  def eval(exp, env)
    return nil if exp.nil?
    send("eval#{exp.schema_class.name}", exp, env)
  end
     
  def evalLiteral(this, env)
    return this.value, nil
  end

  def evalColor(this, env)
    return @factory.Color(this.r, this.g, this.b), nil
  end
  
  def evalPrim(this, env)
    op = this.op.to_sym
    case op
    when :| then 
      val = this.args.any? do |a|
        v, _ = eval(a, env)
        v
      end
      #puts "BINARY #{this.op.to_sym} = #{val}"
    when :& then 
      val = this.args.all? do |a|
        v, _ = eval(a, env)
        v
      end
      #puts "BINARY #{this.op.to_sym} = #{val}"
    when :"?" then
      v, _ = eval(this.args[0], env)
      #puts "IF #{this.args[0]} ==> #{v}"
      if v
        return eval(this.args[1], env)
      else
        return eval(this.args[2], env)
      end
    else
      args = this.args.collect do |a|
        v, _ = eval(a, env)
        v
      end
      a = args.shift
      val = a.send(this.op.to_sym, *args)
      #puts "BINARY #{a}.#{this.op.to_sym}(#{args}) = #{val}"
    end
    return val, nil
  end
  
  def evalField(this, env)
    a, _ = eval(this.base, env)
    return nil, nil if a.nil?  # NOTE THIS IS A HACK!!!
    return a._id, Address.new(a, this.field) if this.field == "_id"
    return a[this.field], Address.new(a, this.field)
  end
    
  def evalInstanceOf(this, env)
    a, _ = eval(this.base, env)
    return Subclass?(a.schema_class, this.class_name), nil
  end
    
  def evalVar(this, env)
    #puts "VAR #{this.name} #{env}"
    throw "undefined variable '#{this.name}'" if !env.has_key?(this.name)
    return env[this.name], nil
  end

end

class Address
  def initialize(obj, field)
    @obj = obj
    @field = field
  end
  
  attr_reader :obj
  
  def value=(val)
    @obj[@field] = val
  end

  def field
    #puts "GET TYPE #{@obj}.#{@field}"
    @obj.schema_class.all_fields[@field]
  end
  
  def is_traversal
    real = field
    if field.computed
      # this determines if a computed field is a selection of a traversal field
      # the semantics it implements is correct, but it does it using a quick hack
      # as a syntactic check, rather than a semantic analysis
      if field.computed =~ /@([^.]*)\.select.*/  # MAJOR HACK!!!
				real = @obj.schema_class.all_fields[$1]    
		  else
		    return false
      end
    end
    return real.traversal
  end
end
