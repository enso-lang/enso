
module CompositeMod
end

def Compose(name, mods, &block)
  mod = CompositeMod.clone
  mod.class_exec do
    mods.each do |m|
      include m
      define_method("#{name}_?") do |fields, type, args={}|
        yield fields, type, args={}
      end
    end
  end
  mod
end
