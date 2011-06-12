
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

    white = @factory.Color(255, 255, 255)
    black = @factory.Color(0, 0, 0)
        
    env = { 
      stencil.root => data,
      :font => @factory.Font("Helvetica", 12, false, false, black),
      :pen => @factory.Pen(1, "solid", black),
      :brush => @factory.Brush(white)
    }
    
    @root = eval(stencil.body, env)
    #puts "DONE"
    ViewDiagram(@root)
  end

  def eval(stencil, env, container = nil)
    newEnv = nil
    font = nil
    pen = nil
    brush = nil
    stencil.props.each do |prop|
      val = eval_exp(prop.exp, env)
      puts "SET #{prop.loc.name} = #{val}"
      newEnv = {}.update(env) if !newEnv
      case prop.loc.name
      when "size" then
        puts "FONT SIZE #{val}"
        newEnv[:font] = font = env[:font]._clone if !font
        font.size = val
      when "weight" then
        font = newEnv[:font] = env[:font]._clone if !font
        font.size = val
      end
    end
    container = WrapStyles.new(container, font, pen, brush) if newEnv    
    send(stencil.schema_class.name, stencil, newEnv || env, container)
  end
  
  def Alt(this, env, container)
    this.alts.each do |alt|
      catch :fail do
        return eval(alt, env, container)
      end
    end
    throw :fail
  end

  def For(this, env, container) 
    r = eval_exp(this.iter, env)
    nenv = {}.update(env)
    r.each_with_index do |v, i|
      nenv[this.var] = v
      nenv[this.index] = i if this.index
      eval(this.body, nenv, container)
    end
  end
    
  def Test(this, env, container)
    test = eval_exp(this.condition, env)
    eval(this.body, env, container) if test
  end

  def Label(this, env, container)
    label = eval_exp(this.label, env)
    result = eval(this.body, env, container)
    @labels[label] = result
    return result
  end
  
  # shapes
  def Container(this, env, container)
    group = @factory.Container(nil, nil, this.direction)
    this.items.each do |item|
      eval(item, env, group.items)
    end
    result container, group
  end
  
  def Text(this, env, container)
    result container, @factory.Text(nil, nil, eval_exp(this.string, env))
  end
  
  def Shape(this, env, container)
    result container, @factory.Shape(nil, nil, eval(this.content, env)) # not many!!!
  end

  def result(container, item)
    return item if container.nil?
    container << item
  end
  
#  def Connector(this, env, container)
#    !ends: ConnectorEnd* / ConnectorEnd.Connector
#    !label: Expression
#  end

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
  
  def Binary(this, env)
    a = eval_exp(this.left, env)
    b = eval_exp(this.right, env)
    case op
    when "+" then return a + b
    when "==" then return a + b
    when "[]" then return a[b]
    end
  end
  
  def Field(this, env)
    a = eval_exp(this.base, env)
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

class WrapStyles
  def initialize(container, font, pen, brush)
    @container = container
    @font = font
    @pen = pen
    @brush = brush
  end
  
  def <<(x)
    x.styles << @font if @font
    x.styles << @pen if @pen
    x.styles << @brush if @brush    
    @container << x
  end
end