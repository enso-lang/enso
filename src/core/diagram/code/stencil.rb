
# apply the stencil to the data to get a diagram (with Menu/action hooks?)
# compute the size/positions of the diagram (relative to window size)
# Display the diagram
# Process mouse clicks as actions

class StencilFrame

  def initialize(stencil, data)
    @stencil = stencil
    @source = source
    env = { stencil.root => data }
    @root = recurse(stencil, env, nil)
    @frame = Diagram.new
  end
  
  def Alt(this, env, container)
    this.alts.each do |alt|
      catch :fail do
        return recurse(alt, obj)
      end
    end
    throw :fail
  end

  def For(this, env, container) 
    r = eval_exp(this.iter, env)
    nenv = {}.update(env)
    coll = r.value
    coll.each_with_index do |v, i|
      nenv[this.var] = v
      nenv[this.index] = i if this.index
      eval(this.body, nenv, container)
    end
  end
    
  def Test(this, env, container)
    test = eval_exp(this.condition, env)
    throw :fail unless test
    eval(this.body, env, container)
  end

  def Label(this, env, container)
    label = eval_exp(this.label, env)
    result = eval(this.body, env, container)
    @labels[label] = result
    return result
  end

    
  class Group(this, env, container)
    result = @factory.Group
    result.direction = this.direction
    #result.props = eval
    eval(this.items)
    this.items.each do |item|
      eval(item, env, result)
    end
    return result
  end
  
  def Text(this, env, container)
    result = @factory.Text
    result.text = eval_exp(this.txt)
    return result
  end
  
  class Shape(this, env, container)
    result = @factory.Shape
    result.content = eval(this.body, env, result) # not many!!!
  end
  
  class Connector(this, env, container)
    !ends: ConnectorEnd* / ConnectorEnd.Connector
    !label: Expression
  end
  


   
end

