
require 'apps/web/code/result'
require 'apps/web/code/web'

module Web::Eval
  class Env
    attr_reader :bindings, :actions

    ROOT_NAME = 'root'

    @@gensym = 0

    # actions is a map from action names 
    # to Action instances.

    def self.root(root, actions_class)
      actions_obj = actions_class.new
      actions = {}
      actions_class.public_instance_methods(false).each do |sym|
        actions[sym.to_s] = Action.new(actions_obj.method(sym))
      end    
      bindings = {ROOT_NAME => Ref.new(root, root._path, root)}
      Env.new(bindings, actions)
    end

    def initialize(bindings, actions)
      @actions = actions
      @bindings = {}.update(bindings)
    end

    def new
      Env.new(bindings, actions)
    end

    def each(&block)
      bindings.each(&block)
    end

    def root
      # NB: returns the actual root, not the Ref
      bindings[ROOT_NAME].value
    end

    def [](name)
      return gensym if name == 'gensym'
      bindings[name] || actions[name]
    end

    def []=(name, result)
      bindings[name] = result
    end

    def to_s
      s = "BINDINGS:\n"
      bindings.each do |k, v|
        s += "\t#{k}\t\t: #{v}\n"
      end
      return s
    end

    private

    def gensym
      @@gensym += 1
      Result.new("$$#{@@gensym}")
    end
  end
end
