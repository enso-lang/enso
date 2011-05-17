

module WebUtils

  class Closure
    attr_reader :env, :block
    def initialize(env, block)
      @env = env
      @block = block
    end
  end

  def convert(field, value)
    if field.type.Primitive? then
      case  field.type.name 
      when 'int' 
        Integer(value)
      when 'bool'
        value == 'true'
      when 'real'
        Float(value)
      when 'str'
        value
      end
    else
      # TODO: this uses @root directly...
      deref(@root, value)
    end
  end

  def deref(obj, ref)
    puts "Dereffing: #{ref}"
    return obj unless ref
    return obj if ref.empty?
    key, ref = deref1(ref)
    deref(obj[key], ref)
  end

  def deref1(ref)
    if ref =~ /^\.([a-zA-Z_][a-zA-Z0-9_]*)(.*)/ then
      # a field deref
      return $1, $2
    elsif ref =~/^\[([0-9]+)\](.*)/ then
      # an integer subscript
      return Integer($1), $2
    elsif ref =~/^\[([^\]]+)\](.*)/ then
      # a string subscript
      return $1, $2
    end
  end
  
  def convert_key(k)
    if k =~ /^[0-9]+/ then
      Integer(k)
    else
      k
    end
  end


  # update actualy does the same dereffing as
  # deref, except it has to traverse the 
  # hashes (representing the path) at the same time
  def update(obj, k, v)
    fn, _ = deref1(k)
    return unless fn

    puts "Updating: #{fn} in #{obj} to #{v}"

    fld = obj.schema_class.fields[fn]

    if v.is_a?(Hash) then
      update_collection(obj[fn], v)
    elsif v.is_a?(Array) then
      update_list(fld, obj[fn], v)
    else
      obj[fn] = convert(fld, v)
    end

    return obj
  end

  def update_list(fld, obj, list)
    list.each_with_index do |elt, i|
      x = convert(fld, elt)
      puts "\tx = #{x}"
      obj << x
    end
  end

  def update_collection(coll, hash)
    # keys are keys in coll
    puts "Updating collection: #{coll} to #{hash}"
    hash.each do |k, v|
      key = convert_key(k)
      v.each do |k, v|
        # delete and and, otherwise hashing messes up
        x = update(coll[key], k, v)
        coll.delete(coll[key])
        coll << x
      end
    end
  end


end
