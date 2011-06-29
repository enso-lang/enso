
# apply the stencil to the data to get a diagram (with Menu/action hooks?)
# compute the size/positions of the diagram (relative to window size)
# Display the diagram
# Process mouse clicks as actions

require 'core/diagram/code/diagram'

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
    @listener = self
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
    @factory = Factory.new(Load('diagram.schema'))
    
    white = @factory.Color(255, 255, 255)
    black = @factory.Color(0, 0, 0)
        
    env = { 
      @stencil.root => @data,
      :font => @factory.Font("Helvetica", 12, "swiss", 400, black),
      :pen => @factory.Pen(1, "solid", black),
      :brush => @factory.Brush(white)
    }
    
    @binding = {}
    @labels = {}
    construct @stencil.body, env do |x| 
      set_root(x) 
    end
    refresh()
    puts "DONE"
    #Print.print(@root)
    on_export
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
  end

  def on_export
    grammar = Loader.load("diagram.grammar")
    File.open("#{@path}-diagram", "w") do |output|
      DisplayFormat.print(grammar, @root, 80, output)
    end
  end

  def notify_change(diagram_object, new_text)
    addr = @binding[diagram_object]
    addr.obj[addr.field] = new_text
  end
  
  def construct(stencil, env, &block)
    send(stencil.schema_class.name, stencil, env, &block)
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
      when "pen.width" then
        #puts "PEN #{val} for #{stencil}"
        pen = newEnv[:pen] = env[:pen]._clone if !pen
        pen.width = val
      when "pen.color" then
        pen = newEnv[:pen] = env[:pen]._clone if !pen
        pen.color = val
      end
    end
    # TODO: why do I need to set the style on every object????
    shape.styles << (font || env[:font])
    shape.styles << (pen || env[:pen])
    shape.styles << (brush || env[:brush])
  end
  
  def Alt(this, env, &block)
    this.alts.each do |alt|
      catch :fail do
        return construct(alt, env, &block)
      end
    end
    throw :fail
  end

  def For(this, env, &block) 
    source, _ = eval(this.iter, env)
    nenv = {}.update(env)
    source.each_with_index do |v, i|
      nenv[this.var] = v
      nenv[this.index] = i if this.index
      construct(this.body, nenv, &block)
    end
  end
    
  def Test(this, env, &block)
    test, _ = eval(this.condition, env)
    construct(this.body, env, &block) if test
  end

  def Label(this, env, &block)
    key = evallabel(this.label, env)
    construct this.body, env do |result|
      #puts "LABEL #{key} => #{result}"
      @labels[key] = result
      block.call(result)
    end
  end

  def evallabel(label, env)
    if label.Prim?    # it has the form Loc[foo]
      tag = label.args[0]
      raise "foo" if !tag.Var?
      tag = tag.name
      index, _ = eval(label.args[1], env)
      return [tag,index]
    else
      val, _ = eval(label, env)
      return val
    end
  end
  
  # shapes
  def Container(this, env, &block)
    group = @factory.Container(nil, nil, this.direction)
    this.items.each do |item|
      construct item, env do |x|
        group.items << x
      end
    end
    make_styles(this, group, env)
    @binding[group] = this
    block.call group
  end
  
  def Text(this, env, &block)
    val, address = eval(this.string, env)
    text = @factory.Text(nil, nil, val)
    make_styles(this, text, env)
    @binding[text] = address
    block.call text
  end
  
  def Shape(this, env, &block)
    shape = @factory.Shape(nil, nil) # not many!!!
    construct this.content, env do |x|
      error "Shape can only have one element" if shape.content
      shape.content = x
    end
    make_styles(this, shape, env)
    @binding[shape] = this
    block.call shape
  end

  def Connector(this, env, &block)
    # label?
    label = nil
    conn = @factory.Connector(nil, nil, label)
    this.ends.each do |e|
      de = @factory.ConnectorEnd(e.arrow, label)
      de.owner = conn
      key = evallabel(e.part, env)
      #puts @labels
      de.to = @labels[key]
      conn.ends << de
    end
    # DEFAULT TO BOTTOM OF FIRST ITEM, AND LEFT OF THE SECOND ONE
    conn.path << @factory.Point(0,0)
    conn.path << @factory.Point(1,0)
    conn.path << @factory.Point(1,1)
    make_styles(this, conn, env)
    @binding[conn] = this
    block.call conn
  end

  #### expressions
  
  def eval(exp, env)
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
    return a._id, Address.new(a, this.field) if this.field == "_id"
    return a[this.field], Address.new(a, this.field)
  end
    
  def evalInstanceOf(this, env)
    a, _ = eval(this.base, env)
    return Subclass?(a.schema_class, this.class_name), nil
  end
    
  def evalVar(this, env)
    #puts "VAR #{this.name} #{env}"
    raise "undefined variable '#{this.name}'" if !env.has_key?(this.name)
    return env[this.name], nil
  end

end

class Address
  def initialize(obj, field)
    self.obj = obj
    self.field = field
  end
  attr_accessor :obj, :field
end
