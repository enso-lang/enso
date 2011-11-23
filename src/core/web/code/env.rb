
require 'core/web/code/result'
require 'core/web/code/web'

module Web::Eval
  class Env
    attr_reader :bindings, :actions

    @@gensym = 0

    # actions is a map from action names 
    # to Action instances.

    def self.root(root, actions_class, root_name = 'root')
      actions_obj = actions_class.new
      actions = {}
      actions_class.public_instance_methods(false).each do |sym|
        actions[sym.to_s] = Action.new(actions_obj.method(sym))
      end    
      bindings = {root_name => Ref.new(root, root._path, root)}
      Env.new(bindings, actions)
    end

    def initialize(bindings, actions)
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

    private

    def gensym
      @@gensym += 1
      Result.new("$$#{@@gensym}")
    end
  end
end
