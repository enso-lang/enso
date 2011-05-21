require 'core/system/load/load'
require 'core/grammar/code/layout'

=begin

Compares two structures for equality

=end

class Equals
  def initialize
    @memo = {}
  end

  def self.equals(a, b)
    return self.new.equals(a, b)
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
end
