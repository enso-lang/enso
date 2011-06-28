
require 'core/web/code/helpers'

module WebUtils
  include Helpers

  def eval_req(name, url, params, out)
    params.each do |k, v|
      log.debug "VAR: #{k}: #{v}"
    end

    env = {}.update(@env)
    news = {}
    params.each do |k, v|
      # assert k is simple name, not a ref with paths
      # because they are formals
      env[k] = v.deref(@root)
    end
    env['self'] = Result.new(url)
    env['errors'] = Result.new({})
    env[name].value.run(env, out)
  end

  def handle_submit(url, params, out)
    errors = {}

    # first create new objects and assign values
    news = {}
    params.each do |k, v|
      lv = k.deref(@root, news)
      rv = v.deref(@root, news)
      lv.update(rv)
    end

    # then execute actions
    params.each do |k, v|
      if action_ref?(k) then
        begin
          handle_action(action(k), action_args(v))
        rescue Redirect => e
          return e.link
        end
      end
    end

    rerender(url, errors, params, news, out)
    return nil
  end


  def field_ref?(key)
    key =~ /^./
  end

  def new_ref?(key)
    key =~ /^@/
  end

  def action_ref?(key)
    key =~ /^action\(.+\)$/
  end

  def action(key)
    return $1 if key =~ /^action\((.+)\)$/
  end

  def action_args(value)
    # TODO? this means : should not occur in 
    # the values themselves...
    value.split(/:/)
  end

  def handle_action(name, args, params)
    args = args.map do |arg|
      deref(@root, v, news)
    end
    actions.send(ac, *args, params)
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

  def delete(root, delete_from_coll_key, v) 
    coll_key = delete_from_coll_key[1..-1] # strip !
    log.debug "COLLKEY: #{coll_key}"
    coll = deref(root, coll_key)
    coll.delete(deref(root, v))
  end


  # update actualy does the same dereffing as
  # deref, except it has to traverse the 
  # hashes (representing the path) at the same time
  def update(obj, k, v, news)
    return update_new(k, v) if new_ref?(k)
    fn = deref1(obj, k)
    log.debug "Updating: #{fn} in #{obj} to #{v}"
    v = deref(obj, v) if field_ref?(v)

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
        # delete and add, otherwise hashing messes up
        # if the key has changed
        #x = update(coll[key], k, v, news)
        #coll.delete(coll[key])
        #coll << x

        # assume only non-primitives are in the collection
        # TODO: rehash after keys have changed?
        update(coll[key], k, v, news)
      end
    end
  end


end
