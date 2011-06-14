=begin

Security model that reads in policies and checks for privileges at run-time

See securefactory.rb for rule semantics

=end

require 'core/schema/tools/union'

class Security
  attr_accessor :user, :root

  def initialize(rulefile)
    allrules = Loader.load(rulefile)
    @allowrules = []
    @denyrules = []
    allrules.rules.each do |r|
      fix_syntax!(r)
      if r.schema_class.name == "AllowRule"
        @allowrules << r
      elsif r.schema_class.name == "DenyRule"
        @denyrules << r
      end
    end
    @root = nil
    @user = nil
    @trusted = 0
  end

  # check if the current user has privileges to perform operation op on object obj or one of its field
  def check_privileges(op, obj, *field)
    #disable checks if in trusted mode
    return true, '' if @trusted > 0

    #verify that obj is part of root. if not, just return success
    return true, '' unless obj.is_a? CheckedObject
    return true, '' unless obj._graph_id == @root._graph_id

    #trusted_mode {
      @trusted = @trusted+1
      #find at least one allow rule that holds
      if @allowrules.none? {|r| check_rule(r, op, obj, *field)}
        @trusted = @trusted-1
        return false, "Operation not allowed"
      end
      #ensure no deny rule holds for this user
      deny = @denyrules.detect do |r|
        check_rule(r, op, obj, *field)
      end
      if deny.nil?
        @trusted = @trusted-1
        return true, ''
      else
        @trusted = @trusted-1
        return false, deny.msg ? deny.msg : 'Permission denied'
      end
    #}
  end

  # return the requirements the fields of the object must satisfy such that the operation is allowed for user
  # given an operation and an object type (and optionally a field)
  # basic formula:
  #   conjunction (forall a in allowrules, s.t. a.op=op and f E a.fields, subst(a.cond))
  #   and not disjunction (forall d in denyrules, s.t d.op=op and f E d.fields, subst(d.cond))
  #      where subst(expr)=bind(expr, {'user'=>@user, rule.action.obj=>'self'})
  def get_allow_constraints(op, obj, *field)
    trusted_mode {
      if @allowrules.empty? and @denyrules.empty?
        return nil   #I would like to return EBoolConst(false) here but I can't even get a factory
      end
      factory = (@allowrules[0] || @denyrules[0]).factory

      #allowcond = disjunction of all relevant allow rules
      allowcond = @allowrules.reduce(nil) do |disj, r|
        if rule_applies?(r, op, obj, *field)
          if r.cond.nil?
            disj.nil? ? factory.EBoolConst(true) : factory.EBinOp('or', disj, factory.EConst(true))
          else
            subst_r = bind!(Copy(factory, r.cond), {'user'=>@user, r.action.obj=>'self'})
            disj.nil? ? subst_r : factory.EBinOp('or', disj, subst_r)
          end
        else
          disj
        end
      end
      #denycond = disjunction of all relevant deny rules
      denycond = @denyrules.reduce(nil) do |disj, r|
        if rule_applies?(r, op, obj, *field)
          if r.cond.nil?
            disj.nil? ? factory.EBoolConst(true) : factory.EBinOp('or', disj, r.factory.EConst(true))
          else
            subst_r = bind!(Copy(factory, r.cond), {'user'=>@user, r.action.obj=>'self'})
            disj.nil? ? subst_r : factory.EBinOp('or', disj, subst_r)
          end
        else
          disj
        end
      end

      # derive the propositional logic formula by allowcond && !denycond
      if allowcond.nil?
        res = factory.EConst(false)
      else
        if denycond.nil?
          res = allowcond
        else
          res = factory.EBinOp('and', allowcond, factory.EUnOp('not', denycond))
        end
      end

      # further reduce this expression if possible
      res = bind!(res, {})

      # return res (do NOT use 'return' as we are inside a proc
      res
    }
  end

  def trusted_mode
    @trusted = @trusted + 1
    res = yield
    @trusted = @trusted - 1
    return res
  end

  #############################################################################
  #start of private section
  private
  #############################################################################

  # fix problematic/unexpected syntax with rules
  def fix_syntax!(rule)
    #remove fields from create and delete rules
    if ["OpCreate","OpDelete"].include? rule.action.op[0]
      #rule.action.fields.clear
      #rule.action.allfields = false
    end
    #add fields to delete
    if ["OpUpdate"].include?(rule.action.op[0]) and rule.action.fields.empty?
      rule.action.allfields = true
    end
  end

  #check if rule is even relevant
  def rule_applies?(rule, op, obj, *field)
    return false unless rule.action.op.map{|op|op.schema_class.name}.include? op
    return false unless obj.schema_class.name == rule.action.type
    if field.empty?
      return false unless rule.action.fields.empty?
    else
      f = field[0]
      return false unless rule.action.allfields or rule.action.fields.map{|f|f.name}.include?(f)
    end
    return true
  end

  # checks if a rule hold and returns a boolean
  def check_rule(rule, op, obj, *field)
    return false unless rule_applies?(rule, op, obj, *field)
    #evaluate condition
    return true if rule.cond.nil?
    env = {'user'=>@user, rule.action.obj=>obj}
    return eval(rule.cond, env)
  end



  ###########################################
  # All the expression evaluation functions #
  ###########################################

  def eval(expr, env)
    send("eval_#{expr.schema_class.name}", expr, env)
  end

  def eval_EBinOp(expr, env)
    e1 = eval(expr.e1, env)
    e2 = eval(expr.e2, env)
    return Kernel::eval("#{e1.inspect} #{expr.op} #{e2.inspect}")
  end

  def eval_EUnOp(expr, env)
    e = eval(expr.e, env)
    return Kernel::eval("#{expr.op} #{e.inspect}")
  end

  def eval_EVar(expr, env)
    #expr name can be a 'path'
    begin
      path = expr.name.split('.')
      res = nil
      path.each do |p|
        if res.nil?
          res = env[p]
        else
          res = res.send(p)
        end
      end
      return res
    rescue
      #if resolving this expression fails for whatever reason
      #usually because the field access expression is malformed (eg misspelled)
      #or because the object is incomplete (?)
      return nil
    end
  end

  def eval_ELForall(expr, env)
    list = eval(expr.list, env)
    list.all? do |l|
      eval(expr.expr, env.merge({expr.var => l}))
    end
  end

  def eval_ELExists(expr, env)
    list = eval(expr.list, env)
    list.any? do |l|
      eval(expr.expr, env.merge({expr.var => l}))
    end
  end

  def eval_EStrConst(expr, env)
    return expr.val
  end

  def eval_EIntConst(expr, env)
    return expr.val
  end

  def eval_EBoolConst(expr, env)
    return expr.val
  end



  # substitute all instances of variables in env with their value
  # also does reduction while binding

  def bind!(expr, env)
    send("bind_#{expr.schema_class.name}!", expr, env)
  end

  def bind_EBinOp!(expr, env)
    expr.e1 = bind!(expr.e1, env)
    expr.e2 = bind!(expr.e2, env)
    if expr.e1.EConst? and expr.e2.EConst?
      return make_const(eval(expr, env), expr.factory)
    elsif expr.op == 'or' or expr.op == '||'
      if expr.e1.EBoolConst? and expr.e1.val==true
        return make_const(true, expr.factory)
      elsif expr.e1.EBoolConst? and expr.e1.val==false
        return expr.e2
      elsif expr.e2.EBoolConst? and expr.e2.val==true
        return make_const(true, expr.factory)
      elsif expr.e2.EBoolConst? and expr.e2.val==false
        return expr.e1
      end
    elsif expr.op == 'and' or expr.op == '&&'
      if expr.e1.EBoolConst? and expr.e1.val==true
        return expr.e2
      elsif expr.e1.EBoolConst? and expr.e1.val==false
        return make_const(false, expr.factory)
      elsif expr.e2.EBoolConst? and expr.e2.val==true
        return expr.e1
      elsif expr.e2.EBoolConst? and expr.e2.val==false
        return make_const(false, expr.factory)
      end
    end
    expr
  end

  def bind_EUnOp!(expr, env)
    expr.e = bind!(expr.e, env)
    if expr.e.EConst?
      return make_const(eval(expr, env), expr.factory)
    elsif expr.e.EUnOp? and (expr.e.op == 'not' or expr.e.op == '!') #dbl negation
      return expr.e.e
    end
    expr
  end

  def bind_EVar!(expr, env)
    path = expr.name.split('.')
    res = env[path[0]]
    if not res.nil?
      if res=="self" #it's a path, eg 'self'
        # replace the physical string and return
        path[0] = res
        expr.name = path.join('.')
        return expr
      else #it's an actual object
        # evaluate its value and substitute it
        val = eval_EVar(expr, env)
        return make_const(val, expr.factory)
      end
    end
    expr
  end

  def bind_ELForall!(expr, env)
    bind!(expr.list, env)
    #remove vars from env which are now outside their scope due to expr.var
    bind!(expr.expr, env.reject {| key, value | key == expr.var })
    expr
  end

  def bind_ELExists!(expr, env)
    bind!(expr.list, env)
    #remove vars from env which are now outside their scope due to expr.var
    bind!(expr.expr, env.reject {| key, value | key == expr.var })
    expr
  end

  def bind_EStrConst!(expr, env)
    expr
  end

  def bind_EIntConst!(expr, env)
    expr
  end

  def bind_EBoolConst!(expr, env)
    expr
  end

  def make_const(val, factory)
    if val.is_a?(String)
      factory.EStrConst(val)
    elsif val.is_a?(Integer)
      factory.EIntConst(val)
    elsif val.is_a?(TrueClass) or val.is_a?(FalseClass)
      factory.EBoolConst(val)
    else
      nil
    end
  end

end
