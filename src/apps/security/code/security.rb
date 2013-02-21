=begin

Security model that reads in policies and checks for privileges at run-time

See securefactory.rb for rule semantics

=end

require 'core/semantics/code/interpreter'
require 'core/expr/code/eval'

module CheckPrivileges
  def check_Authentication(allowrules, denyrules, args=nil)
    obj = args[:obj]

    #verify that obj is part of root. if not, just return success
    if not obj.is_a? Factory::MObject
      [true, '']

    #find at least one allow rule that holds
    elsif allowrules.none? {|r| check(r, args)}
      [false, "Operation not allowed"]

    #ensure no deny rule holds for this user
    else
      deny = denyrules.detect {|r| check(r, args)}
      if deny.nil?
        [true, '']
      else
        [false, deny.msg ? deny.msg : 'Permission denied']
      end
    end
  end

  def check_Rule(action, cond, args={})
    check(action, args) and (cond.nil? or Interpreter(EvalExpr).eval(cond, args.merge({:env=>{"user"=>args[:user], action.obj=>args[:obj]}})))
  end

  def check_Action(op, type, fields, allfields, args=nil)
    if ! op.map{|op|op.schema_class.name}.include? args[:op]
      false
    elsif type != args[:obj].schema_class.name
      false
    elsif args[:field].nil?
      fields.empty?
    else
      allfields or fields.map{|f|f.name}.include? args[:field].to_s
    end
  end
end

class Security

  attr_accessor :user, :root

  def initialize(rulefile)
    allrules = rulefile
    @allowrules = allrules.allowrules
    @denyrules = allrules.denyrules
    @user = nil
    @trusted = 0
  end

  # check if the current user has privileges to perform operatr on object obj or one of its field
  def check_privileges(op, obj, field=nil)
    Interpreter.compose(CheckPrivileges).new.check(allrules, [op: op, :obj=>obj, :field=>field])
  end

  # return the requirements the fields of the object must satisfy such that the operation is allowed for user
  # given an operation and an object type (and optionally a field)
  # basic formula:
  #   conjunction (forall a in allowrules, s.t. a.op=op and f E a.fields, subst(a.cond))
  #   and not disjunction (forall d in denyrules, s.t d.op=op and f E d.fields, subst(d.cond))
  #      where subst(expr)=bind(expr, {'user'=>@user, rule.action.obj=>'self'})
  def get_allow_constraints(op, classname, *field)
    trusted_mode {
      if @allowrules.empty? and @denyrules.empty?
        return nil   #I would like to return EBoolConst(false) here but I can't even get a factory
      end
      factory = (@allowrules[0] || @denyrules[0]).factory

      #allowcond = disjunction of all relevant allow rules
      allowcond = @allowrules.reduce(nil) do |disj, r|
        if rule_applies?(r, op, classname, *field)
          if r.cond.nil?
            factory.EBoolConst(true)
          else
            subst_r = bind!(Copy(factory, r.cond), {"user"=>@user, r.action.obj=>"@self"})
            disj.nil? ? subst_r : factory.EBinOp('or', disj, subst_r)
          end
        else
          disj
        end
      end
      #denycond = disjunction of all relevant deny rules
      denycond = @denyrules.reduce(nil) do |disj, r|
        if rule_applies?(r, op, classname, *field)
          if r.cond.nil?
            factory.EBoolConst(true)
          else
            subst_r = bind!(Copy(factory, r.cond), {"user"=>@user, r.action.obj=>"@self"})
            disj.nil? ? subst_r : factory.EBinOp('or', disj, subst_r)
          end
        else
          disj
        end
      end

      # derive the propositional logic formula by allowcond && !denycond
      if allowcond.nil?
        res = factory.EBoolConst(false)
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

end
