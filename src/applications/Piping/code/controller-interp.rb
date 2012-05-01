
module ExecuteController
  include LValueExpr
  include EvalExpr

  def init_Controller(globals, args=nil)
    globals.each do |g|
      if g.var.EVar?
        s = self
        l = LambdaEnv.new(g.var.name) {s.eval(g.val, args)}
        args[:env].set_grandparent(l)
      else
        self.eval(g, args)
      end
    end
  end

  def execute_Controller(constraints, current, args=nil)
    execute(current, args)
    constraints.each do |c|
      execute(c, args)
    end
  end

  def execute_Constraint(cond, action, args=nil)
    if self.eval(cond, args)
      self.eval(action, args)
    end
  end

  def execute_State(commands, transitions, args=nil)
    #test conditions BEFORE executing current state!!!
    moved = transitions.detect do |trans|
      execute(trans, args)
    end
    if !moved
      args1 = args.set(:env) {|env| e=HashEnv.new; e.set_parent(env); e}
      commands.each do |c|
        self.eval(c, args1)
      end
    end
  end

  def execute_Transition(guard, target, args=nil)
    if self.eval(guard, args)
      args[:control].current = target
      true
    else
      false
    end
  end

  def eval_Assign(var, val, args=nil)
    lvalue(var, args).value = self.eval(val, args)
  end

  def eval_TurnSplitter(splitter, percent, args=nil)
    args[:env][splitter].position = [[percent, 1.0].min, 0.0].max
  end
end
