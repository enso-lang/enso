=begin

Security model that reads in policies and checks for privileges at run-time

=end

class Security
  attr_accessor :user, :root

  def initialize(rulefile)
    allrules = Loader.load(rulefile)
    @allowrules = []
    @denyrules = []
    allrules.rules.each do |r|
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

  # checks if a rule hold and returns a boolean
  def check_rule(rule, op, obj, *field)
    #check if rule is even relevant
    return false unless rule.action.op.map{|op|op.schema_class.name}.include? op
    return false unless obj.schema_class.name == rule.action.type
    if field.empty?
      return false unless rule.action.fields.empty?
    else
      f = field[0]
      return false unless rule.action.fields.map{|f|f.name}.include? f
    end
    #evaluate condition
    return true if rule.cond.nil?
    env = {'user'=>@user, rule.action.obj=>obj}
    return eval(rule.cond, env)
  end

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

  end

  def eval_ELExists(expr, env)

  end

  def eval_EStrConst(expr, env)
    return expr.val
  end

  def eval_EIntConst(expr, env)
    return expr.val
  end

end
