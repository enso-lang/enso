=begin

A default security object that does not do any authentication

=end

class NullSecurity

  attr_accessor :user, :root

  def initialize(rulefile=nil)
    @factory = Factory.new(Loader.load('auth.schema'))
  end

  def check_privileges(op, obj, *field)
    return true
  end

  def get_allow_constraints(op, classname, *field)
    return @factory.EBoolConst(true)
  end

  def trusted_mode
    yield
  end

end
