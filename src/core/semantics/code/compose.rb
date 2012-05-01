
module CompositeMod; end

def Define(name, &block)
  mod = CompositeMod.clone
  mod.class_exec do
    define_method("#{name}_?") do |fields, type, args={}|
      yield fields, type, args
    end
  end
  mod
end

def Before(op1, op2)
  Define(op2) do |fields, type, args={}|
    __call(op1, fields, type, args)
    super fields, type, args
  end
end

def After(op1, op2)
  Define(op1) do |fields, type, args={}|
    super fields, type, args
    __call(op2, fields, type, args)
  end
end
