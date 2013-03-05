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
          if !equals(a_val, b_val)
            puts "fail2 #{a_val} #{b_val}"
            return false
          end
        elsif a_val.is_a? Factory::List
          return false if !equals_list(a_val, b_val)
        elsif a_val.is_a? Factory::Set
          return false if !equals_set(a_val, b_val)
        end
      end

    return true
  end

  def equals_list(l1, l2)
    return false if l1.size!=l2.size
    l1.keys.each do |i|
      return false if !equals(l1[i], l2[i])
    end
    return true
  end

  def equals_set(l1, l2) #like equals list but ignores order
    return false if l1.size!=l2.size
    l1.keys.each do |i|
      return false if !equals(l1[i], l2[i])
    end
    return true
  end
end

def equals(a,b)
  Equals.equals(a, b)
end
