
module ExecuteController
  include LValueExpr
  include EvalExpr
  
  operation :execute, :init, :isEVar

  def init_Controller(globals, args=nil)
    globals.each do |g|
      if g.var.isEVar
        #Note that a new interpreter is 'needed' here because
        # suppose the outer interpreter is being debugged, you certainly don't want
        # this lambda env expresssion to show up in the debugger as well
        l = LambdaEnv.new(g.var.name) {Interpreter(EvalExpr).eval(g.val[], args)}
        args[:env].set_grandparent(l)
      else
        g.eval
      end
    end
  end
  def isEVar_EVar; true; end
  def isEVar_?(type, fields, args); false; end

  def execute_Controller(constraints, current)
    current.execute
    constraints.each do |c|
      c.execute
    end
  end

  def execute_Constraint(cond, action)
    if cond.eval
      action.eval
    end
  end

  def execute_State(commands, transitions, args=nil)
    #test conditions BEFORE executing current state!!!
    moved = transitions.detect do |trans|
      trans.execute
    end
    if !moved
      commands.each do |c|
        env1 = HashEnv.new.set_parent(args[:env])  #create a new blank env page
        c.eval(env: env1)
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
