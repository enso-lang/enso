
require 'core/web/code/result'

# TODO: add to Web::Eval
class Env
  attr_reader :bindings, :actions

  @@gensym = 0

  # actions is a map from action names 
  # to action *methods* wrapped in Handler
  # or (just method?); not Action 

  def initialize(bindings = {}, actions = {})
    @actions = actions
    @bindings = {}.update(bindings)
  end

  def new
    Env.new(bindings, actions)
  end

  def [](name)
    return gensym if name == 'gensym'
    @bindings[name] || @actions[name]
  end

  def []=(name, result)
    @bindings[name] = result
  end

  def bind_action!(name, method)
    @actions[name] = Web::Eval::Action.new(method)
  end
  
  private

  def gensym
    @@gensym += 1
    Web::Eval::Result.new("$$#{@@gensym}")
  end

end
