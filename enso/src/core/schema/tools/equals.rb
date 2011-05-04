

require 'cyclicmap'

class Equals < MemoBase

  def recurse(this, o1, o2)
    if @memo[[this, o1]].equal?(o2) then
      return true
    end
    @memo[[this, o1]] = o2
    #puts "Sending to: #{this.schema_class.name}"
    send(this.schema_class.name, this, o1, o2)
  end

  def self.equals(schema, o1, o2)
    self.new.recurse(schema, o1, o2)
  end

  def Schema(this, o1, o2)
    #puts o1.schema_class
    #puts o2.schema_class
#     if !this.classes.include?(o1.schema_class) || 
#         !this.classes.include?(o2.schema_class) then
#       raise "Objects' classes are not in schema"
#     end
    return false unless o1.schema_class == o2.schema_class
    recurse(o1.schema_class, o1, o2)
  end

  def Primitive(this, o1, o2)
    #puts "Comparing primitives: #{o1} ==? #{o2}"
    o1 == o2
  end

  def Klass(this, o1, o2)
    ##puts "KLASS: #{this}, #{o1}, #{o2}"
    this.fields.inject(true) do |eq, f|
      eq && recurse(f, o1, o2)
    end
  end

  def unordered(this, o1, o2)
    #puts "Unordered comparison"
    b1 = o1[this.name].any? do |x|
      o2[this.name].any? do |y|
        #puts "Comparing  o1.#{x} and o2.#{y}"
        recurse(this.type, x, y)
      end
    end
    
    #puts "B1 = #{b1}"

    b2 = o2[this.name].any? do |x|
      o1[this.name].any? do |y|
        #puts "Comparing o2.#{x} and o1.#{y}"
        recurse(this.type, x, y)
      end
    end

    #puts "B2 = #{b2}"
    #puts "----------> returning in unordered #{b1 && b1}"
    return b1 && b2
  end

  def ordered(this, o1, o2) 
    each2 = o2[this.name].each
    b = o1[this.name].all? do |x|
      recurse(this.type, x, each2.next)
    end
    #puts "----------> returning in ordered #{b}"
    return b
  end

  def many(this, o1, o2)
    #puts "In many: #{this.name} #{o1[this.name].length} #{o2[this.name].length}"
    return false unless o1[this.name].length == o2[this.name].length
    if this.inverse then 
      unordered(this, o1, o2)
    else
      ordered(this, o1, o2)
    end
  end

  def single(this, o1, o2)
    #puts "o1 and o2 are: '#{o1[this.name]}'  '#{o2[this.name]}'"
    #puts "o1 and o2 are: '#{o1[this.name].class}'  '#{o2[this.name].class}'"
    #puts "o1 and o2 are: '#{o1[this.name].nil?}'  '#{o2[this.name].nil?}'"
    return false unless o1[this.name].nil? == o2[this.name].nil?
    return true if o1[this.name].nil?
    #puts "Comparing single: #{this.name} #{this.type}"
    b = recurse(this.type, o1[this.name], o2[this.name])
    #puts "---------> returning in single: #{b}"
    return b
  end

  def Field(this, o1, o2)
    #puts "Comparing FIELD: #{this.name}"
    # o1 and o2 are the owners
    if this.many then
      many(this, o1, o2)
    else
      single(this, o1, o2)
    end
  end

end
