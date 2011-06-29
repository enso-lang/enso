
require 'ostruct'

class BaseClosure
  def initialize(eval, env, abs)
    @eval = eval
    @env = env
    @abs = abs
  end

  def formals
    @abs.formals
  end

  def tail
    @abs.tail
  end

  def with_args(args, block, call_env, out)

    # Bind arguments in clean environment
    env = {}.update(@env)
    # but conses in an env between call_env
    inter_env = {}.update(call_env)

    i = 0
    bind_tail = true
    formals.each do |frm|
      if frm.cons then
        bind_tail = false
        target = []
        env[frm.name] = target
        
        puts "Making a cons-closure for #{frm.name}"
        # Bind a closure that will update the current
        # formal parameter when the block (if any) is executed.
        inter_env[frm.cons.name] = ConsClosure.new(@eval, env,
                                                              frm.cons,
                                                              target)
      else
        # A normal expression is just evaluated and put in the env.
        puts "Setting normal formal param #{frm.name}"
        env[frm.name] = @eval.eval_exp(args[i], call_env)
        i += 1
      end
    end

    if tail && bind_tail && block then
      # bind the block as a closure to name of tail
      puts "Capturing tail block"
      env[tail.name] = Closure.new(@eval, call_env, tail, block)
      puts "Capturing tail block done: env[#{tail.name}] = #{env[tail.name]}, block="
    end

    if !bind_tail && block then
      # run the constructor block to fill in the rest of env
      puts "into interenv and stuff"
      @eval.eval(block, inter_env, out)
    end

    yield env
  end
end

class Closure < BaseClosure
  def initialize(eval, env, abs, body)
    super(eval, env, abs)
    @body = body
  end

  def apply(args, block, call_env, out)
    with_args(args, block, call_env, out) do |env|
      @eval.eval(@body, env, out)
    end
  end
end


class Function < Closure
  def initialize(eval, env, abs)
    super(eval, env, abs, abs.body)
  end

  def name
    @abs.name
  end

  def run(env, out)
    @eval.eval(@body, env, out)
  end    

end

class ConsClosure < BaseClosure
  def initialize(eval, env, abs, target)
    super(eval, env, abs)
    @target = target
  end

  def apply(args, block, call_env, out)
    # add a record to target with fields according to formals

    Print.print(block)

    factory = block.factory
    record = {}
    with_args(args, block, call_env, out) do |env|
      bound_tail = true
      formals.each do |frm|
        puts "Formal #{frm.name}, #{frm.cons}"
        if frm.cons then
          bound_tail = false
        end
        record[frm.name] = env[frm.name]
        puts "record[#{frm.name}] = #{record[frm.name].value}"
      end
      if tail && block && bound_tail then
        # block is bound to the name of tail
        # set the closure as value 
        name = tail.name
        record[name] = env[name]
        puts "2. record[#{name}] = #{record[name]}"
      end
    end
    @target << record
    nil
    blablabla
  end

end
