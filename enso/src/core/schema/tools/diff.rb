

require 'cyclicmap'

class DiffBase < MemoBase

  def self.diff(o1, o2)
    self.new.diff(o1, o2)
  end
  
  def diff(o1, o2)
    Klass(o1, o2)
  end

  def Type(this, o1, o2)
    return send(this.schema_class.name, o1, o2)
  end

  def Primitive(o1, o2)
    o1 == o2
  end

  def Klass(o1, o2)
    if o1.nil? || o2.nil?
      return o1.nil? == o2.nil?
    end
    #puts "#{o1.schema_class.name} ==? #{o2.schema_class.name}"
    return false if o1.schema_class.name != o2.schema_class.name
    #puts "DIFF #{o1} #{o2}"
 
    return true if @memo[[o1, o2]]
    @memo[[o1, o2]] = true
    
    o1.schema_class.fields.each do |f|
      Field(f, o1, o2)
    end
    return true # diffs have already been accounted for
  end

  def Field(field, o1, o2)
    #puts "FIELD: #{field}"
    return if field.computed
    # o1 and o2 are the owners
    if field.many then
      many(field, o1, o2)
    else
      single(field, o1, o2)
    end
  end

  def single(field, o1, o2)
    if !Type(field.type, o1[field.name], o2[field.name])
      #puts "SINGLE #{field.type}. #{o1[field.name]} <-> #{o2[field.name]}"
      different_single(o2, field, o2[field.name], o1[field.name])
    end
  end

  def many(field, o1, o2)
    if SchemaSchema.key(field.type) then 
      keyed(field, o1, o2)
    else
      ordered(field, o1, o2)
    end
  end

  def ordered(field, o1, o2) 
    o1[field.name].zip(o2[field.name]).each do |left, right|
      if right.nil?
        different_insert(o2, field, left)
      elsif left.nil?
        different_delete(o2, field, right)
      else
        Type(field.type, left, right)
      end
    end
  end

  def keyed(field, o1, o2)
    keys = o1[field.name].keys | o2[field.name].keys
    keys.each do |key_val|
      left = o1[field.name][key_val]
      right = o2[field.name][key_val]
      if right.nil?
        different_insert(o2, field, left)
      elsif left.nil?
        different_delete(o2, field, right)
      else
        Type(field.type, left, right)
      end
    end
  end
end


class Diff < DiffBase
  def initialize()
    super()
    @diffs = []
  end

  def diff(o1, o2)
    super(o1, o2)
    @diffs
  end

  def different_single(target, field, old, new)
    @diffs << [:change, target, field.name, old, new]
  end

  def different_insert(target, field, new)
    @diffs << [:insert, target, field.name, new]
  end
  
  def different_delete(target, field, old)
    @diffs << [:delete, target, field.name, old]
  end
end

