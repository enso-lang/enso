require 'core/system/library/cyclicmap'
require 'core/diff/code/equals'
require 'core/diff/code/diff'
require 'core/schema/tools/copy'

# here is an idea for a new version
# def Merge(x, y, renaming = {})
#   ApplyDiff( AdditionsOnly( Diff(x, y, renaming) ), x) 
# end
  
module Merge
  class Identify < MemoBase
    def self.placeholder_char
      "_"
    end
    
    def initialize(mapping, source, target, renaming = {})
      super()
      @mapping = mapping
      @source_root = source
      @target_root = target
      @mapping[source] = target 
      @renaming = renaming
    end

    def identify(obj)
      return if obj.nil? || @memo[obj]
      @memo[obj] = true
      obj.schema_class.fields.each do |f|
        Field(f, obj)
      end
    end

    def Field(field, obj)
      #puts "Visiting #{field} & #{obj}"
      if field.type.Primitive?
        if field.key
          name = obj[field.name]
          if @renaming[name] then
            analog = lookup_object(obj)
            @mapping[obj] = analog
            #puts "MAP #{obj} to #{analog}"
          end
        end
      else
        if !field.many
          x = obj[field.name]
          identify(x)
        else
          obj[field.name].each do |x|
            identify(x)
          end
        end
      end  
    end

    # find an object with an equivalent name  
    def lookup_object(left_obj)
      # this scans the source during the recursive calls, 
      # then follows the same path in the target on the way out
      raise "Keys cannot be null" if left_obj.nil?
      #puts "Looking up #{left_obj}"
      rel_key_field = ClassKeyRel(left_obj.schema_class)
      if rel_key_field.nil?
        raise "Keys should connect to root but stop at #{left_obj}" if left_obj != @source_root
        return @target_root
      else
        key_field = ClassKey(left_obj.schema_class)

        raise "Key relationship fields must have inverses" if rel_key_field.inverse.nil?
        raise "A relationship key must have a data key as well" if key_field.nil?

        right_base_obj = lookup_object(left_obj[rel_key_field.name])
        left_id = left_obj[key_field.name]
        right_id = @renaming[left_id] || left_id
        right_obj = right_base_obj[rel_key_field.inverse.name][right_id]
        #puts "IDENTIFY #{left_obj}.#{key_field.name}=#{left_id} with #{right_obj}"
        raise "Could not find analogous object to #{left_obj}" if right_obj.nil?
        return right_obj
      end
    end
  end

  class Merge
    def initialize()
      super()
    end

    def merge(from, to, factory, renaming = {})
      # adds identifications to the memo table
      @identity = {}

      @renaming = renaming

      @copier = Copy.new(factory, @identity)
      to = @copier.copy(to)

      id = Identify.new(@identity, from, to, renaming)
      id.identify(from)
      #p @identity

      
      diff(from, to)
      #p @diffs
      to.finalize
      to
    end

    # just insert everything from the left
    def ordered(field, o1, o2) 
      o1[field.name].each do |left|
        different_insert(o2, field, left)
      end
    end

    def keyed(field, o1, o2)
      #puts "KEY #{field} #{o1[field.name]} #{o2[field.name]}"
      o1[field.name].keys.each do |key_val|
        left = o1[field.name][key_val]
        #puts "KEYVAL #{key_val}"
        if @renaming[key_val] then
          right = o2[field.name][@renaming[key_val]]
          #puts "RENAMED #{field.name} #{left} #{right}"
          raise "could not find object named #{key_val}" if right.nil?
          Type(field.type, left, right)
        else
          right = o2[field.name][key_val]
          #puts "RIGHT: #{field.name}, o1: #{o1}, o2: #{o2}, #{right}"
          raise "attempt to overwrite object named #{key_val}" unless right.nil?
          different_insert(o2, field, left)
        end
      end
    end

    def different_single(target, field, old, new)
      return if new.nil?
      if field.type.Primitive?
        return if field.key && new[0] == Identify.placeholder_char
        target[field.name] = new
        #puts "SET #{target}.#{field.name} = #{new}"
      else
        raise "Merge cannot change single-valued field #{target}.#{field.name} from #{old} to #{new}"
      end
    end

    def different_insert(target, field, new)
      #puts "COPYING #{target[field.name]}.#{field.name} #{new}"
      target[field.name] << @copier.copy(new)
    end
    
    def different_delete(target, field, old)
      raise "Merge cannot delete from #{target}.#{field.name}"
    end
  end
end

def merge(x, y, ren = {})
  Merge::Merge.new.merge(x, y, y._graph_id, ren)
end
  
