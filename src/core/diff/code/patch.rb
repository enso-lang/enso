=begin

Apply a diff result conforming to delta schema as a patch script on an object

=end

require 'core/system/library/schema'

module Patch

  def self.patch(o, deltas)
    factory = o.factory
    fixes = deltas
      fixes.each do |fix|
       case fix.type
          when Diff.add
            val = factory[fix.value.name]
            owner = fix.path.owner.deref(o)
            if owner.is_a?(ManagedData::MObject)
                owner[fix.path.last.value] = val
            elsif owner.is_a? ManagedData::Set
                owner << val
            elsif owner.is_a? ManagedData::List
                owner.insert(fix.path.last.value, val)
            end 
          when Diff.del
            owner = fix.path.owner.deref(o)
            val = fix.path.deref(o)
            if owner.is_a?(ManagedData::MObject)
                owner[fix.path.last.value] = nil
            elsif owner.is_a? ManagedData::Set
                owner.delete(val)
            elsif owner.is_a? ManagedData::List
                owner.delete(val)
            end
          when Diff.mod
            val = fix.value.is_a?(Paths::Path) ? fix.value.deref(o) : fix.value
            owner = fix.path.owner.deref(o)
            if owner.is_a?(ManagedData::MObject)
                owner[fix.path.last.value] = val
            elsif owner.is_a? ManagedData::Set
                owner << val
            elsif owner.is_a? ManagedData::List
                owner.insert(fix.path.last.value, val)
            end 
        end
      end
    o
  end

end
