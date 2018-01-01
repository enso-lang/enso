# Security model that reads in policies and checks for privileges at run-time
#
# See securefactory.rb for rule semantics

require 'core/semantics/code/interpreter'
require 'core/expr/code/eval'
require 'core/schema/code/factory'


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
