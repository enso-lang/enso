
# A renamer that re-routes dispatches to new type names
# This can be used to update an interpreter

module RedispatchMod
end

def Redispatch(type_map, action, m)
  mod = RedispatchMod.clone
  mod.class_exec do
    include m

    type_map.each do |from,to|
      define_method("redispatch_#{from}") do |fields, type, args={}|
      __call(op, fields, type.schema.types[to], args)
      end
    end

    define_method("redispatch_?") do |fields, type, args={}|
      __call(op, fields, type, args)
    end
  end
  mod
end
