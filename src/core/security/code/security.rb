# Security model that reads in policies and checks for privileges at run-time
#
# See securefactory.rb for rule semantics

require 'core/semantics/code/interpreter'
require 'core/expr/code/eval'
require 'core/schema/code/factory'

module CheckPrivileges
  def check_Authentication(allowrules, denyrules, args=nil)
    obj = args[:obj]

    #verify that obj is part of root. if not, just return success
    if not obj.is_a?(Factory::MObject)
      true

    #find at least one allow rule that holds
    elsif allowrules.none? {|r| check(r, args)}
      false  # , "Operation not allowed"]

    #ensure no deny rule holds for this user
    else
      deny = denyrules.detect {|r| check(r, args)}
      if deny.nil?
        true
      else
        false   # , deny.msg ? deny.msg : 'Permission denied']
      end
    end
  end

  def check_Rule(action, cond, args={})
    if check(action, args)
      if cond.nil?
        true
      else
        Interpreter(EvalExpr).eval(cond, args.merge({:env=>{"user"=>args[:user], action.obj=>args[:obj]}}))
      end
    end
  end

  def check_Action(op, type, fields, allfields, args=nil)
    if ! op.map{|op|op.schema_class.name}.include?(args[:op])
      false
    elsif type != args[:obj].schema_class.name
      false
    elsif args[:field].nil?
      fields.empty?
    else
      allfields or fields.map{|f|f.name}.include?(args[:field].to_s)
    end
  end
end

class Security

  def initialize(rulefile)
    @allrules = rulefile
    
#    @allowrules = allrules.allowrules
#    @denyrules = allrules.denyrules
  end

	def execute(user, query)
	  return nil
	end


end
