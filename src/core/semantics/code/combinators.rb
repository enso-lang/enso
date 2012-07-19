
# Around advice that wraps one interpreter with another
module Wrap
  def wrap(mod, action=operations[0])
    newmod = self.clone
    newmod.send(:include, mod)
    mod.operations.each do |op|
      newmod.send(:eval, "
        define_method(:#{op}) do |args={}, &block|
          #{action}(args+{op: :#{op}}) do |args2={}|
            super(args+args2, &block)
          end
        end")
    end
    newmod
  end
end

# Control module that specifies when a node is executed
# controlling interpreter must define traverse operation
module Traverse
  include Wrap

  def traverse(mod)
    newmod = wrap(mod, :control)
    newmod.send(:include, TraversalHelper)
  end

  module TraversalHelper
    operation :traverse

    #workqueue management
    def prepend(obj); @@workqueue.unshift(obj).uniq! end
    def append(obj); (@@workqueue << obj).uniq! end
    def pop; @@workqueue.shift end
    def done?; @@workqueue.empty? end
    def queue; @@workqueue end
    def start?; @@start ? !@@start=false : false end

    def control(args, &block)
      if start?
        prepend(self)
        until done?
          pop.send(args[:op], args)
        end
      else
        traverse &block
      end
    end

    def __init
      super
      @@workqueue = []
      @@start = true
    end
    def __hidden_calls; super+[:traverse]; end
  end

end

# Sum of two interpreters, with the second overriding the first
module Compose
  def self.compose(mod1, mod2)
    newmod = mod1.clone
    newmod.send(:include, mod2)
    newmod
  end
  def compose(mod)
    Compose.compose(self, mod)
  end
end

# Give an alias to an operation. Old name not removed
module Rename
  def self.rename(mod, oldname, newname)
    newmod = mod.clone
    newmod.define_method(newname) do |args={}, &block|
      send(oldname, args, &block)
    end
    newmod.eval("@operations << :#{newname}")
    newmod
  end
  def rename(oldname, newname)
    Rename.rename(self, oldname, newname)
  end
end
