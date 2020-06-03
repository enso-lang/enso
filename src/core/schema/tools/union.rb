require 'core/schema/code/factory'

#=begin

#This file creates the copy of two structures.
#The copy U of structures A and B has all the
#objects of both A and B. 

#=end
require 'enso'

module Union
  
  class CopyInto
    def initialize(factory)
      @memo = {}
      @factory = factory
    end
  
    # computes the copy of structures given root nodes a and b  
    def copy(a, b)
      build(a, b)
      link(true, a, b)
    end
    
    # build walks the spine of the two structures and matches up
    # corresponding objects. The most important thing to keep in 
    # mind is that either a or b (or both) can be nil, if there is no
    # corresponding structure in the other structure.
    # This function builds all the new objects and also initialized
    # the primitive fields. Primitive fields must be initialized
    # first so that the keys will be defined before objects are added
    # to keyed collections
    def build(a, b)
      if !a.nil?
        raise "Union of incompatible objects #{a} and #{b}" if a && b && a.schema_class.name != b.schema_class.name
        @memo[a.identity] = new = b || @factory[a.schema_class.name]
        #puts "BUILD #{a} + #{b} ==> #{new}"
        new.schema_class.fields.each do |field|
          a_val = begin a[field.name]
          rescue 
            nil 
          end
          b_val = begin b[field.name] 
          rescue 
            nil 
          end
          if !a_val.nil? or !b_val.nil?
            if field.type.is_a?("Primitive")
              if !a_val.nil?
                if a && b && a_val != b_val then
                  puts "UNION WARNING: changing #{new}.#{field.name} from '#{b_val}' to '#{a_val}'"
                end
                new[field.name] = a_val
              end
            elsif field.traversal
              if !field.many
                build(a_val, b_val)
              else
                a_val.each_with_match(b_val) do |a_item, b_item|
                  build(a_item, b_item)
                end
              end
            end
          else
            if !new[field.name].nil?
              puts "skipping #{new}.#{field.name} as #{new[field.name]}"
            end
          end
        end
      end
    end
  
    # creates the cross-links in the CopyInto. The "traversal" field is used
    # to go one stage past the spine, to relate linked objects.
    def link(traversal, a, b)
      if a.nil?
        b 
      else
        new = @memo[a.identity]
        #puts "LINK #{a} + #{b} ==> #{new}"
        if !new
          p @memo
          raise "Traversal did not visit every object a=#{a} b=#{b}" 
        end
        if traversal
          a.schema_class.fields.each do |field|
            a_val = a[field.name]
            b_val = b && b[field.name]
            if !field.type.is_a?("Primitive")
              if !field.many
                val = link(field.traversal, a_val, b_val)
                new[field.name] = val
              else
                a_val.each_with_match(b_val) do |a_item, b_item|
                  item = link(field.traversal, a_item, b_item)
                  new[field.name] << item  # TODO: WHY WAS THIS HERE: unless new[field.name].include? item
                end
              end
            end
          end
        end
        new
      end
    end
  end        
  
  def self.CopyInto(factory, a, b)
    CopyInto.new(factory).copy(a, b)
  end   
  
  def self.Copy(factory, a)
    CopyInto.new(factory).copy(a, nil).finalize
  end
  
  def self.Clone(a)
    Copy(a.factory, a)
  end
      
  def self.Union(factory, *parts)
    copier = CopyInto.new(factory)
    result = nil
    parts.each do |part|
      result = copier.copy(part, result)
    end
    result.finalize
  end   
  
  def self.union(a, b)
    f = Factory::SchemaFactory.new(a.graph_identity.schema)
    Union(f, a, b)
  end
end
