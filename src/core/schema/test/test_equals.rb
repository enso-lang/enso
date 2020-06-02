
require 'test/unit'

require 'core/system/load/load'

require 'core/schema/tools/copy'
require 'core/schema/tools/print'
require 'core/schema/tools/equals'

class EqualityTest < Test::Unit::TestCase
  SS = Load::load('schema.schema')
  GS = Load::load('grammar.schema')
  GG = Load::load('grammar.grammar')
  
  def print_eq(s, x, y)
    s1 = ''
    s2 = ''
    Print.new(s1).recurse(x)
    Print.new(s2).recurse(y)
    if Equals.equals(x, y) then
      assert_equal(s1, s2, "objects are equal but print differently")
    else
      assert_not_equal(s1, s2, "objects are not equal, but print the same")
    end
  end
    



  def test_not_equals
    s1 = SS
    s3 = GS
    s4 = GG

    assert(!Equals.equals(s3, s4))
  end



  def test_transitive
    s1 = SS
    s2 = Copy.new(Factory::SchemaFactory.new(SS)).copy(s1)
    s3 = Copy.new(Factory::SchemaFactory.new(SS)).copy(s2)
    assert(Equals.equals(s1, s3))
  end

end
