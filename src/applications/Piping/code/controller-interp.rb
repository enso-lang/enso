
module ExecuteController
  include LValueExpr
  include EvalExpr
  
  operation :execute, :init, :isEVar

  def init_Controller(globals, args=nil)
    globals.each do |g|
      if g.var.isEVar(args)
        #Note that a new interpreter is 'needed' here because
        # suppose the outer interpreter is being debugged, you certainly don't want
        # this lambda env expresssion to show up in the debugger as well
        l = LambdaEnv.new(g.var.name) {Interpreter(EvalExpr).eval(g.val[], args)}
        args[:env].set_grandparent(l)
      else
        g.eval(args)
      end
    end
  end
  def isEVar_EVar(args=nil); true; end
  def isEVar_?(type, fields, args=nil); false; end

  def execute_Controller(constraints, current, args=nil)
    current.execute(args)
    constraints.each do |c|
      c.execute(args)
    end
  end

  def execute_Constraint(cond, action, args=nil)
    if cond.eval(args)
      action.eval(args)
    end
  end

  def execute_State(commands, transitions, args=nil)
    #test conditions BEFORE executing current state!!!
    moved = transitions.detect do |trans|
      trans.execute(args)
    end
    if !moved
      args1 = args.set(:env) {|env| e=HashEnv.new; e.set_parent(env); e}
      commands.each do |c|
        c.eval(args1)
      end
    end
  end

  def execute_Transition(guard, target, args=nil)
    if guard.eval(args)
      args[:control].current = target[]
      true
    else
      false
    end
  end

  def eval_Assign(var, val, args=nil)
    var.lvalue(args).value = val.eval(args)
  end

  def eval_TurnSplitter(splitter, percent, args=nil)
    args[:env][splitter].position = [[percent, 1.0].min, 0.0].max
  end
end
