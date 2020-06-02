
# A default security object that does not do any authentication



class NullSecurity

  attr_accessor :user, :root

  def initialize(rulefile=nil)
    @factory = Factory::SchemaFactory.new(Load::load('auth.schema'))
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
