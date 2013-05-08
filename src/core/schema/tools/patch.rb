#=begin

#Apply a diff result conforming to delta schema as a patch script on an object

#=end

require 'core/system/library/schema'

module Patch

  def self.patch(o, deltas)
    factory = o.factory
    fixes = deltas
      fixes.each do |fix|
        if fix.value.nil?
          val = nil
        elsif fix.path.type(o).type.Primitive?
          val = fix.value
        elsif fix.path.type(o).traversal
          val = factory[fix.value]
        else
          val = fix.value.deref(o)
        end
        case fix.type
          when Diff.add
            fix.path.insert(o, val)
          when Diff.del
            next unless fix.path.deref? o
            fix.path.delete(o)
          when Diff.mod
            fix.path.assign(o, val)
        end
      end
    o
  end

end
