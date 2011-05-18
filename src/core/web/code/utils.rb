

module WebUtils

  class Closure
    attr_reader :env, :block
    def initialize(env, block)
      @env = env
      @block = block
    end
  end

  def defines?(name)
    @tenv[name]
  end
  
  def eval_req(name, params, out)
    env = {}
    news = {}
    params.each do |k, v|
      if v =~ /^\./ then
        env[k] = Result.new(deref(@root, v), v)
      elsif v =~ /^@/ then
        obj, _ = create(v, @root._graph_id, news)
        log.debug "Converting param: #{k}  #{v}"
        # it cannot have subpaths, since it is new
        # so the path is actually v itself
        env[k] = Result.new(obj, v)
      else
        env[k] = Result.new(v)
      end
    end
    eval(@tenv[name].body, env, out, nil)
  end

  def handle_submit(params, out)
    params.each do |k, v|
      log.debug "VAR: #{k}: #{v}"
    end

    key = params.keys.find do |name|
      # todo factor this sigil out and reuse it also with gensym
      name =~ /^\$\$/
    end
    url = params["redirect_#{key}"]

    # update the assignments    
    # and create new objects

    # first create new objects and assign values
    news = {}
    params.each do |k, v|
      if k =~ /^@/ then
        obj, path = create(k, @root._graph_id, news)
        update(obj, path, v, news)
      end
    end

    # then do additionaly assignments
    params.each do |k, v|
      if k !~ /^@/
        update(@root, k, v, news)
      end
    end

    return url
  end


  def tag(name, attrs, out)
    out << "<#{name}"
    attrs.each do |k, v|
      out << " #{k}=\"#{@coder.encode(v)}\""
    end
    out << ">"
    yield
    out << "</#{name}>"
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
    log.debug "Dereffing: #{ref}"
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
  def update(obj, k, v, news)
    return update_new(k, v) if k =~ /^@/

    fn, _ = deref1(k)
    return unless fn

    log.debug "Updating: #{fn} in #{obj} to #{v}"

    fld = obj.schema_class.fields[fn]

    if v.is_a?(Hash) then
      update_collection(obj[fn], v, news)
    elsif v.is_a?(Array) then
      update_list(fld, obj[fn], v)
    elsif news[v] then
      if fld.many then
        obj[fn] << news[v]
      else
        obj[fn] = news[v]
      end
    else
      obj[fn] = convert(fld, v)
    end

    return obj
  end

  def create(str, fact, news)
    if str =~ /^(@([a-zA-Z_][a-zA-Z0-9_]*):[0-9]+)(.*)/ then
      log.debug "STR: #{str} $1: #{$1}"
      # only create if not already in the "news" map
      news[$1] ||= fact[$2]
      log.debug "#{$3}"
      return news[$1], $3
    end
    raise "Invalid 'new' ref: #{str}"
  end

  def update_list(fld, obj, list)
    list.each_with_index do |elt, i|
      x = convert(fld, elt)
      log.debug "\tx = #{x}"
      obj << x
    end
  end

  def update_collection(coll, hash, news)
    # keys are keys in coll
    log.debug "Updating collection: #{coll} to #{hash}"
    hash.each do |k, v|
      key = convert_key(k)
      v.each do |k, v|
        # delete and and, otherwise hashing messes up
        x = update(coll[key], k, v, news)
        coll.delete(coll[key])
        coll << x
      end
    end
  end


end
