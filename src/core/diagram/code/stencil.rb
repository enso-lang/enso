
# apply the stencil to the data to get a diagram (with Menu/action hooks?)
# compute the size/positions of the diagram (relative to window size)
# Display the diagram
# Process mouse clicks as actions

require 'core/diagram/code/diagram'

# render(Stencil, data) = diagram

class StencilFrame 

  def initialize(stencil, data)
    @stencil = stencil
    @data = data
    @factory = Factory.new(Load('diagram.schema'))
    @labels = {}

    white = @factory.Color(255, 255, 255)
    black = @factory.Color(0, 0, 0)
        
    env = { 
      stencil.root => data,
      :font => @factory.Font("Helvetica", 12, "swiss", 400, black),
      :pen => @factory.Pen(1, "solid", black),
      :brush => @factory.Brush(white)
    }
    
    eval stencil.body, env do |x| 
      @root = x 
    end
    puts "DONE"
    Print.print(@root)
    
    ViewDiagram(@root)
  end

  def eval(stencil, env, &block)
    send stencil.schema_class.name, stencil, env, &block
  end
  
  def make_styles(stencil, shape, env)
    newEnv = nil
    font = nil
    pen = nil
    brush = nil
    stencil.props.each do |prop|
      val = eval_exp(prop.exp, env)
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
        return eval(alt, env, &block)
      end
    end
    throw :fail
  end

  def For(this, env, &block) 
    r = eval_exp(this.iter, env)
    nenv = {}.update(env)
    r.each_with_index do |v, i|
      nenv[this.var] = v
      nenv[this.index] = i if this.index
      eval(this.body, nenv, &block)
    end
  end
    
  def Test(this, env, &block)
    test = eval_exp(this.condition, env)
    eval(this.body, env, &block) if test
  end

  def Label(this, env, &block)
    key = eval_label(this.label, env)
    eval this.body, env do |result|
      #puts "LABEL #{key} => #{result}"
      @labels[key] = result
      block.call(result)
    end
  end

  def eval_label(label, env)
    if label.Prim?    # it has the form Loc[foo]
      tag = label.args[0]
      raise "foo" if !tag.Var?
      tag = tag.name
      index = eval_exp(label.args[1], env)
      return [tag,index]
    else
      return eval_exp(label, env)
    end
  end
  
  # shapes
  def Container(this, env, &block)
    group = @factory.Container(nil, nil, this.direction)
    this.items.each do |item|
      eval item, env do |x|
        group.items << x
      end
    end
    make_styles(this, group, env)
    block.call group
  end
  
  def Text(this, env, &block)
    text = @factory.Text(nil, nil, eval_exp(this.string, env))
    make_styles(this, text, env)
    block.call text
  end
  
  def Shape(this, env, &block)
    s = @factory.Shape(nil, nil) # not many!!!
    eval this.content, env do |x|
      s.content = x
    end
    make_styles(this, s, env)
    block.call s
  end

  def Connector(this, env, &block)
    # label?
    label = nil
    conn = @factory.Connector(nil, nil, label)
    this.ends.each do |e|
      de = @factory.ConnectorEnd(e.arrow, label)
      de.owner = conn
      key = eval_label(e.part, env)
      #puts @labels
      de.to = @labels[key]
      conn.ends << de
    end
    # DEFAULT TO BOTTOM OF FIRST ITEM, AND LEFT OF THE SECOND ONE
    conn.path << @factory.Point(0,0)
    conn.path << @factory.Point(1,0)
    conn.path << @factory.Point(1,1)
    make_styles(this, conn, env)
    block.call conn
  end

  #### expressions
  
  def eval_exp(exp, env)
    #puts "EVAL #{exp}"
    r = send(exp.schema_class.name, exp, env)
    #puts "RETURN #{exp} = #{r}"
    return r
  end
     
  def Literal(this, env)
    return this.value
  end

  def Color(this, env)
    return @factory.Color(this.r, this.g, this.b)
  end
  
  
  def Prim(this, env)
    op = this.op.to_sym
    case op
    when :| then 
      return this.args.any? do |a|
        eval_exp(a, env)
      end
    when :& then 
      return this.args.all? do |a|
        eval_exp(a, env)
      end
    else
      args = this.args.collect do |a|
        eval_exp(a, env)
      end
      a = args.shift
      #puts "BINARY #{a}.#{this.op.to_sym}(#{args})"
      return a.send(this.op.to_sym, *args)
    end
  end
  
  def Field(this, env)
    a = eval_exp(this.base, env)
    return a._id if this.field == "_id"
    return a[this.field]
  end
    
  def InstanceOf(this, env)
    a = eval_exp(this.base, env)
    return Subclass?(a.schema_class, this.class_name)
  end
    
  def Var(this, env)
    #puts "VAR #{this.name} #{env}"
    raise "undefined variable '#{this.name}'" if !env.has_key?(this.name)
    return env[this.name]
  end

end

