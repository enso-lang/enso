
require 'test/unit'

require 'core/system/load/load'

require 'core/schema/code/factory'

require 'core/schema/tools/copy'
require 'core/schema/tools/print'
require 'core/diff/code/equals'

class EqualityTest < Test::Unit::TestCase
  SS = Loader.load('schema.schema')
  GS = Loader.load('grammar.schema')
  GG = Loader.load('grammar.grammar')
  
  def print_eq(s, x, y)
    s1 = ''
    s2 = ''
    Print.new(s1).recurse(x)
    Print.new(s2).recurse(y)
    if Equals.equals(s, x, y) then
      assert_equal(s1, s2, "objects are equal but print differently")
    else
      assert_not_equal(s1, s2, "objects are not equal, but print the same")
    end
  end
    



  def test_not_equals
    s1 = SS
    s3 = GS
    s4 = GG

    assert(!Equals.equals(SS, s3, s4))

    assert_raise(Exception, "cannot compare grammars using schemaschema") do
      Equals.equals(SS, s4, s4)
    end

    assert_raise(Exception, "should not compare grammars to schemas") do
      Equals.equals(SS, s4, s3)
    end

    assert_raise(Exception, "should not compare schemas to grammars") do
      Equals.equals(SS, s3, s4)
    end

    assert_raise(Exception, "should not compare schemas to grammars as if grammars") do
      Equals.equals(GS, s3, s4)
    end
  end



  def test_transitive
    s1 = SS
    s2 = Copy.new(Factory.new(SS)).copy(s1)
    s3 = Copy.new(Factory.new(SS)).copy(s2)
    assert(Equals.equals(SS, s1, s3))
  end

end
