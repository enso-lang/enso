
require 'core/query/code/operators'

class EvalOQL

  include Operators
 
  def initialize(factory)
    @factory = factory
  end

  def run(oql, root)
    env = {'root' => root}
    eval(oql, env)
    eval(oql.query, env)
  end

  def eval(this, env)
    puts "Eval: #{this}, #{env}"
    send(this.schema_class.name, this, env)
  end

  def OQL(this, env)
    this.defs.each do |d|
      eval(d, env)
    end
  end

  def Def(this, env)
    env[this.name] = query
  end

  def Var(this, env)
    env[this.name]
  end

  def Call(this, env)
    args = this.args.map do |arg|
      eval(arg, env)
    end
    send("builtin_#{this.name}", *args)
  end
    

  def New(this, env)
    struct = {}
    this.bindings.each do |binding|
      struct[binding.name] = eval(binding.exp, env)
    end
    if this.type then
      @factory[this.type]
    else
      return struct
    end
  end

  def Tuple(this, env)
    first = eval(this.first, env)
    rest = this.rest.map do |exp|
      eval(exp, env)
    end
    # TODO: should be hash
    return first, *rest
  end
  
  def Field(this, env)
    obj = eval(this.obj, env)
    return obj[this.name]
    # TODO: arguments/methods
  end

  def Subscript(this, env)
    obj = eval(this.obj, env)
    sub = eval(this.arg, env)
    return obj[sub]
  end

  def Slice(this, env)
    raise "NYI"
  end

  def Unary(this, env)
    val = eval(this.arg, env)
    send(UNOPS[this.op], val)
  end

  def Binary(this, env)
    lhs = eval(this.lhs, env)
    rhs = eval(this.rhs, env)
    send(BINOPS[this.op], lhs, rhs)
  end

  def Compare(this, env)
    lhs = eval(this.lhs, env)
    rhs = eval(this.rhs, env)
    send(COMPOPS[this.op], lhs, rhs, this.quantifier)
  end

  def Like(this, env)
    raise "NYI"
  end

  def Comprehension(this, env)
    coll = eval(this.coll, env)
    send(this.quantifier, this.var, coll, this.body)
  end

  %w(Nil Bool Int Float Str).each do |type|
    module_eval %Q{
      def #{type}(this, env)
        this.value
      end
    }
  end

  def Select(this, env)
    # TODO: we only allow named froms now
    # TOOD: no support for aggregation (count etc)
    # group by, ordering and having.

    froms = eval_nameds(this.from, env)

    env = {}.update(env)
    result = {}
    result.default = []
    cartesian(froms) do |tuple| 
      env.merge!(tuple)
      if eval(this.condition, env) then
        tuple = eval_nameds(this.projections, env)
        tuple.each do |k, v|
          result[k] <<= v
        end
      end
    end
    return result
  end

  def eval_nameds(nameds, env)
    hsh = {}
    i = 0
    nameds.each do |named|
      key = named.name || (i += 1)
      hsh[key] = eval(named.exp, env)
    end
    return hsh
  end

  def cartesian(cols, prev = {}, &block)
    key = cols.keys.first
    val = cols[key]
    
    if cols.size == 1 then
      val.each do |x|
        yield prev.update({key => x})
      end
    else
      val.each do |elem|
        new = {}.update(cols)
        new.delete(key)
        cartesian(new, prev.update({key => elem}), &block)
      end
    end
  end


end
