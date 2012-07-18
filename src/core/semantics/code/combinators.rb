
# Around advice that wraps one interpreter with another
module Wrap
  def wrap(mod)
    newmod = self.clone
    action = operations[0] 
    newmod.send(:include, mod)
    mod.op_methods.each do |sym|
      m = mod.instance_method(sym)
      
      if !sym.to_s.end_with? "?"
        param_names = m.parameters.select{|k,v|k==:req}.map{|k,v|v.to_s}
        has_args = m.parameters.include? [:opt, :args]
        newmod.send(:eval, "
        define_method(:#{sym}) do |#{(param_names+["args={}", "&block"]).join","}|
          #{action}(args+{op: '#{sym}'}) do |args2={}| 
            _call(m, args+args2) do |nargs|
              super(#{(param_names+(has_args ? ["nargs"] : [])+["&block"]).join","})
            end
          end
        end")
      else
        newmod.send(:eval, "
        define_method(:#{sym}) do |type, fields, args, &block|
          #{action}(args+{op: '#{sym}'}) do |args2={}|
            _call(m, args+args2) do |nargs|
              super(type, fields, nargs, &block)
            end
          end
        end")
      end
    end
    newmod
  end
end

# Control module that specifies when a node is executed
module Control
  module Helper
    def start?
      if @@start 
        @@start=false
        true 
      else
        false
      end
    end
    def prepend(obj)
      @@workqueue.unshift(obj).uniq!
    end
    def append(obj)
      (@@workqueue << obj).uniq!
    end
    def pop
      nex = @@workqueue[0]
      @@workqueue = @@workqueue[1..-1]
      nex
    end
    def done?
      @@workqueue.empty?
    end
    def queue
      @@workqueue
    end
    def __init
      @@workqueue = []
      @@start = true
    end
  end

  def control(mod)
    newmod = self.clone
    action = operations[0]
    newmod.send(:include, Helper)
    newmod.send(:include, mod)
    mod.op_methods.each do |sym|
      m = mod.instance_method(sym)
      op = sym.to_s.split('_')[0]
      if !sym.to_s.end_with? "?"
        param_names = m.parameters.select{|k,v|k==:req}.map{|k,v|v.to_s}
        has_args = m.parameters.include? [:opt, :args]
        newmod.send(:eval, "
        define_method(:#{sym}) do |#{(param_names+["args={}", "&block"]).join","}|
          if start?
            append(self)
            until done?
              pop.send(:#{op}, args)
            end
          else
            #{action}(args+{op: '#{sym}'}) do |args2={}| 
              _call(m, args+args2) do |nargs|
                super(#{(param_names+(has_args ? ["nargs"] : [])+["&block"]).join","})
              end
            end
          end
        end")
      else
        newmod.send(:eval, "
        define_method(:#{sym}) do |type, fields, args, &block|
          if start?
            append(self)
            until done?
              pop.send(:#{op}, args)
            end
          else
            #{action}(args+{op: '#{sym}'}) do |args2={}|
              _call(m, args+args2) do |nargs|
                super(type, fields, nargs, &block)
              end
            end
          end
        end")
      end
    end
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
    newmod.eval("@operations << :#{newname}")
    newmod
  end
  def rename(oldname, newname)
    Rename.rename(self, oldname, newname)
  end
end
