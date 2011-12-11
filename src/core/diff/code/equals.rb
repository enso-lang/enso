require 'core/system/load/load'
require 'core/grammar/render/layout'

=begin

Deep equality based on object tree structure and primitive values

=end

class Equals 

  def initialize()
    @memo = {}
  end
  
  def self.equals(a, b)
    self.new.equals(a, b)
  end

  def equals(a, b)
      return true if a == b
      return false if a.nil? || b.nil? || a.schema_class.name != b.schema_class.name
      return true if @memo[[a, b]]
      @memo[[a, b]] = true

      a.schema_class.fields.each do |field|
        a_val = a[field.name]
        b_val = b[field.name]
  
        if field.type.Primitive?
          return false if a_val != b_val
        elsif !field.many
          return false if !equals(a_val, b_val)
        else
          a_val.outer_join(b_val) do |a_item, b_item|
            return false if !equals(a_item, b_item)
          end
        end
      end

    return true
  end

  def self.equals_list(l1, l2)
    return false if l1.length!=l2.length
    for i in 0..l1.length-1
      return false if !Equals.equals(l1[i], l2[i])
    end
    return true
  end

  def self.equals_set(l1, l2) #like equals list but ignores order 
    return false if l1.length!=l2.length
    l1.keys.each do |i|
      return false if l2.detect {|x| Equals.equals(l1[i], x)}
    end
    return true
  end
end

def equals(a,b)
  Equals.equals(a, b)
end
