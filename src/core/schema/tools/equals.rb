#=begin

#Deep equality based on object tree structure and primitive values

#=end
require 'enso'

module Equals
class EqualsClass

  def initialize()
    @memo = {}
  end
  
  def self.equals(a, b)
    self.new.equals(a, b)
  end

  def equals(a, b)
    if a == b
      true
    elsif a.nil? || b.nil? || a.schema_class.name != b.schema_class.name
      false
    elsif @memo[[a, b]]
      true
    else
      res = true
      @memo[[a, b]] = true

      a.schema_class.fields.each do |field|
        a_val = a[field.name]
        b_val = b[field.name]
        if field.type.is_a?("Primitive")
          res = false if a_val != b_val
        elsif !field.many
          if !equals(a_val, b_val)
            puts "fail2 #{a_val} #{b_val}"
            res = false
          end
        elsif a_val.is_a?(Factory::List)
          res = false if !equals_list(a_val, b_val)
        elsif a_val.is_a?(Factory::Set)
          res = false if !equals_set(a_val, b_val)
        end
      end
      res
    end
  end

  def equals_list(l1, l2)
    if l1.size!=l2.size
      false
    else
      res = true
      l1.keys.each do |i|
        res = false if !equals(l1[i], l2[i])
      end
      res
    end
  end

  def equals_set(l1, l2) #like equals list but ignores order
    if l1.size!=l2.size
      false
    else
      res = true
      l1.keys.each do |i|
        res = false if !equals(l1[i], l2[i])
      end
      res
    end
  end
end

def self.equals(a,b)
  EqualsClass.equals(a, b)
end

end
