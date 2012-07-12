
# Around advice that wraps one interpreter with another
module Wrap
  def wrap(mod, action=:execute)
    newmod = self.clone
    newmod.send(:include, mod)
    mod.instance_methods.select{|m|m.to_s.include? "_"}.each do |sym|
      m = mod.instance_method(sym)

      param_names = m.parameters.select{|k,v|k==:req}.map{|k,v|v.to_s}
      newmod.send(:eval, "
      define_method(:#{sym}) do |#{(param_names+["args={}", "&block"]).join","}|
        #{action}(args) {|args2={}| super(#{(param_names+["args+args2", "&block"]).join","}) }
      end")
    end
    newmod
  end
end

# Control module that specifies when a node is executed
module Control
  def control(mod)
    newmod = self.clone
    newmod.
    newmod
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
    newmod
  end
  def rename(oldname, newname)
    Rename.rename(self, oldname, newname)
  end
end
